-- Schema proposal for the planning module.
-- Review with TV1 before applying to the shared Supabase project.
-- Assumes public.personal_topics.id is a UUID.

create table if not exists public.plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references auth.users (id) on delete cascade,
  personal_topic_id uuid not null
    references public.personal_topics (id) on delete cascade,
  title text not null check (length(btrim(title)) > 0),
  description text,
  start_date date,
  end_date date,
  status text not null default 'active'
    check (status in ('active', 'completed', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null
    references public.plans (id) on delete cascade,
  user_id uuid not null
    references auth.users (id) on delete cascade,
  phase text not null check (length(btrim(phase)) > 0),
  title text not null check (length(btrim(title)) > 0),
  description text,
  due_date date,
  status text not null default 'todo'
    check (status in ('todo', 'in_progress', 'done')),
  order_index integer not null default 0,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists plans_personal_topic_id_idx
  on public.plans (personal_topic_id);
create index if not exists plans_user_id_idx
  on public.plans (user_id);
create index if not exists tasks_plan_id_idx
  on public.tasks (plan_id);
create index if not exists tasks_user_id_idx
  on public.tasks (user_id);

create or replace function public.set_plan_task_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists plans_set_updated_at on public.plans;
create trigger plans_set_updated_at
  before update on public.plans
  for each row
  execute function public.set_plan_task_updated_at();

drop trigger if exists tasks_set_updated_at on public.tasks;
create trigger tasks_set_updated_at
  before update on public.tasks
  for each row
  execute function public.set_plan_task_updated_at();

alter table public.plans enable row level security;
alter table public.tasks enable row level security;

grant select, insert, update, delete on public.plans to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;

drop policy if exists plans_select_own on public.plans;
create policy plans_select_own
  on public.plans for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists plans_insert_own on public.plans;
create policy plans_insert_own
  on public.plans for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists plans_update_own on public.plans;
create policy plans_update_own
  on public.plans for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists plans_delete_own on public.plans;
create policy plans_delete_own
  on public.plans for delete to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists tasks_select_own_plan on public.tasks;
create policy tasks_select_own_plan
  on public.tasks for select to authenticated
  using (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  );

drop policy if exists tasks_insert_own_plan on public.tasks;
create policy tasks_insert_own_plan
  on public.tasks for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  );

drop policy if exists tasks_update_own_plan on public.tasks;
create policy tasks_update_own_plan
  on public.tasks for update to authenticated
  using (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  )
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  );

drop policy if exists tasks_delete_own_plan on public.tasks;
create policy tasks_delete_own_plan
  on public.tasks for delete to authenticated
  using (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.plans
      where plans.id = tasks.plan_id
        and plans.user_id = (select auth.uid())
    )
  );
