import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

const GEMINI_MODEL = "gemini-3.8-flash";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, x-client-info, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

const GEMINI_TIMEOUT_MS = 25_000;
const GEMINI_MAX_RETRIES = 1;
const GEMINI_RETRY_DELAY_MS = 800;

const RETRYABLE_GEMINI_STATUSES = new Set([500, 502, 503, 504]);

type GeminiResult = {
  ok: boolean;
  status: number;
  body: string;
};

async function callGemini(
  apiKey: string,
  payload: unknown,
): Promise<GeminiResult> {
  for (let attempt = 0; attempt <= GEMINI_MAX_RETRIES; attempt++) {
    const controller = new AbortController();
    const startedAt = Date.now();

    const timeoutId = setTimeout(() => {
      controller.abort();
    }, GEMINI_TIMEOUT_MS);

    try {
      console.info(`[Gemini] Attempt ${attempt + 1} started`);

      const response = await fetch(GEMINI_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });

      // Đọc body trước khi kết thúc timeout.
      const responseBody = await response.text();

      console.info(
        `[Gemini] Status ${response.status}, ` +
          `elapsed ${Date.now() - startedAt}ms`,
      );

      // Thành công hoặc lỗi không nên retry.
      if (
        response.ok ||
        !RETRYABLE_GEMINI_STATUSES.has(response.status) ||
        attempt === GEMINI_MAX_RETRIES
      ) {
        return {
          ok: response.ok,
          status: response.status,
          body: responseBody,
        };
      }

      console.warn(`[Gemini] Temporary error ${response.status}. Retrying...`);
    } catch (error) {
      if (controller.signal.aborted) {
        console.error(`[Gemini] Timeout after ${GEMINI_TIMEOUT_MS}ms`);

        throw new Error("GEMINI_TIMEOUT");
      }

      if (attempt === GEMINI_MAX_RETRIES) {
        throw error;
      }

      console.warn("[Gemini] Network error. Retrying...", error);
    } finally {
      clearTimeout(timeoutId);
    }

    // Chờ trước khi thực hiện lần thử tiếp theo.
    await new Promise((resolve) => setTimeout(resolve, GEMINI_RETRY_DELAY_MS));
  }

  throw new Error("GEMINI_REQUEST_FAILED");
}

export default {
  fetch: withSupabase(
    { auth: ["publishable", "secret"] },
    async (req, _ctx) => {
      // Handle CORS preflight
      if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
      }

      if (req.method !== "POST") {
        return jsonResponse({ error: "Method not allowed." }, 405);
      }

      try {
        const apiKey = Deno.env.get("GEMINI_API_KEY");

        if (!apiKey) {
          return jsonResponse(
            { error: "Gemini API Key is not configured." },
            500,
          );
        }

        const body = await req.json();

        const interests = body.interests ?? "";
        const skills = body.skills ?? "";
        const technologies = body.technologies ?? "";
        const description = body.description ?? "";

        // Validate input
        if (
          !String(interests).trim() &&
          !String(skills).trim() &&
          !String(technologies).trim() &&
          !String(description).trim()
        ) {
          return jsonResponse(
            { error: "Please provide at least one input field." },
            400,
          );
        }

        const prompt = `
Bạn là một chuyên gia tư vấn định hướng đề tài đồ án tốt nghiệp
cho sinh viên ngành Công nghệ thông tin và các ngành liên quan.

Dựa trên thông tin sinh viên cung cấp, hãy đề xuất từ 3 đến 5 đề tài
đồ án tốt nghiệp thực tế, phù hợp với trình độ và có thể triển khai.

THÔNG TIN SINH VIÊN:
- Sở thích: ${interests}
- Kỹ năng hiện có: ${skills}
- Công nghệ đã biết hoặc muốn sử dụng: ${technologies}
- Mô tả thêm: ${description}

YÊU CẦU:
1. Đề tài phải phù hợp với thông tin sinh viên cung cấp.
2. Ưu tiên đề tài có tính thực tiễn và phạm vi phù hợp đồ án tốt nghiệp.
3. Không đề xuất đề tài quá chung chung hoặc không khả thi.
4. Mỗi đề tài phải có mục tiêu rõ ràng.
5. Mô tả hướng triển khai theo các bước hoặc thành phần chính.
6. Đề xuất công nghệ phù hợp.
7. Trả lời bằng tiếng Việt.
8. Không tự khẳng định đề tài đã được nhà trường phê duyệt.
9. Chỉ trả về JSON theo cấu trúc được yêu cầu, không thêm Markdown.
`;

        const geminiResult = await callGemini(apiKey, {
          contents: [
            {
              role: "user",
              parts: [{ text: prompt }],
            },
          ],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 4096,
            responseMimeType: "application/json",
            responseSchema: {
              type: "OBJECT",
              properties: {
                suggestions: {
                  type: "ARRAY",
                  items: {
                    type: "OBJECT",
                    properties: {
                      title: { type: "STRING" },
                      description: { type: "STRING" },
                      objectives: { type: "STRING" },
                      methodology: { type: "STRING" },
                      field: { type: "STRING" },
                      technologies: {
                        type: "ARRAY",
                        items: { type: "STRING" },
                      },
                    },
                    required: [
                      "title",
                      "description",
                      "objectives",
                      "methodology",
                      "field",
                      "technologies",
                    ],
                  },
                },
              },
              required: ["suggestions"],
            },
          },
        });

        if (!geminiResult.ok) {
          console.error(
            "Gemini API error:",
            geminiResult.status,
            geminiResult.body.slice(0, 2000),
          );

          if (geminiResult.status === 429) {
            return jsonResponse(
              {
                error: "Gemini API quota exceeded. Please try again later.",
              },
              429,
            );
          }

          if (geminiResult.status === 503) {
            return jsonResponse(
              {
                error: "Gemini đang quá tải. Vui lòng thử lại sau.",
              },
              503,
            );
          }

          return jsonResponse(
            {
              error: "Gemini API request failed.",
            },
            502,
          );
        }

        let geminiData;

        try {
          geminiData = JSON.parse(geminiResult.body);
        } catch (error) {
          console.error("Cannot parse Gemini response:", error);

          return jsonResponse(
            {
              error: "Gemini returned an invalid JSON response.",
            },
            502,
          );
        }

        const generatedText = geminiData?.candidates?.[0]?.content?.parts
          ?.map((part: { text?: string }) => part.text ?? "")
          .join("");

        if (!generatedText) {
          return jsonResponse(
            { error: "Gemini returned an empty response." },
            502,
          );
        }

        const parsedData = JSON.parse(generatedText);

        const suggestions = parsedData.suggestions;

        if (!Array.isArray(suggestions) || suggestions.length === 0) {
          return jsonResponse(
            { error: "No topic suggestions were generated." },
            502,
          );
        }

        // Limit results to 5 suggestions.
        return jsonResponse({
          suggestions: suggestions.slice(0, 5),
        });
      } catch (error) {
        console.error("AI topic suggestions error:", error);

        if (error instanceof Error && error.message === "GEMINI_TIMEOUT") {
          return jsonResponse(
            {
              error: "Gemini phản hồi quá chậm. Vui lòng thử lại sau.",
            },
            504,
          );
        }

        if (error instanceof TypeError) {
          return jsonResponse(
            {
              error: "Không thể kết nối đến Gemini API.",
            },
            502,
          );
        }

        return jsonResponse(
          {
            error: "An unexpected error occurred while generating topics.",
          },
          500,
        );
      }
    },
  ),
};
