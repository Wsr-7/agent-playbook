# agent-playbook

**English** · [简体中文](#zh)

A personal playbook of skills for AI coding agents, distilled from how I actually work — one continuous path from interrogating a requirement to accepting a delivery. The starting point was to drop the constraints of heavyweight frameworks like superpowers and keep only the parts that still change a strong model's behavior, then absorb the good ideas from other skills and plugins for my own use. Some pieces are my own (delivery, reviewit, the gate system); others are mature skills adopted and adapted as needed (the grilling series, from mattpocock).

## Table of Contents

- [Design philosophy](#design-philosophy)
- [Workflow map](#workflow-map)
- [Skills](#skills)
- [Quick Start](#quick-start)
- [Project-side companions](#project-side-companions-templates)
- [Credits](#credits)
- [License](#license)

## Design philosophy

A strong model has already internalized most "process knowledge" (how to do TDD, how to write a plan), so this repo does not teach process. Every rule earns its place by passing three questions:

1. **Does the model know how to do it?** If yes → don't write it (it's internalized; writing it is a token-wasting no-op).
2. **Does the model do it by default?** Known but not done by default (anti-default discipline) → **write it**.
3. **Who holds the information?** Held in a human's head (decisions, seam trade-offs, when to accept) → **write it as a protocol that asks/confirms with the human**.

Four derived principles:

- **Gate over opinion**: acceptance runs deterministic checks first (exit codes); model judgment covers only what a script cannot. "A reviewer without a gate is a second optimist."
- **Backbone + attached engines**: groundwork is always present; specialized engines trigger on demand and are referenced, not inlined.
- **Deliberate minor duplication**: core behavior rules are intentionally repeated in a few lines across engines so each skill file is independently distributable — take any one of them and it stands alone, depending on no other file in this repo, no plugin, and no personal config. **Do not "helpfully deduplicate" during maintenance.**
- **Skill body stays platform-agnostic**: trigger prefixes and platform differences (`/name` vs `$name`, hooks, agent personas, etc.) go in the README or in platform-specific files (like `agents/openai.yaml`), never in the `SKILL.md` body — the body is a cross-platform workflow instruction, and stuffing platform detail into it is pollution.

## Workflow map

```text
task comes in
├─ (auto) groundwork applies: baseline judgment underneath everything
├─ requirement fuzzy?              → /grill-me, branch-by-branch interrogation (need a glossary/ADR? /grill-with-docs)
├─ big task?                       → /delivery: freeze spec → plan → implement (small checkpoint commits)
│                                    → gate script → independent review (≤2 rounds) → delivery report
├─ stuck on a hard bug?            → (auto) diagnosing-bugs: build the red-light command first, hypotheses second
├─ accepting an agent's output?    → /reviewit: gate first → judgment review → human-verification table
├─ session ending / switching?     → /handoff
└─ git conflict?                   → (auto) resolving-merge-conflicts
```

One-line memory: **groundwork everywhere, grill before you touch, delivery for the big things, diagnose when stuck, review at handover, handoff when you leave.**

## Skills

| Skill | Role |
| --- | --- |
| groundwork | Behavior baseline: make assumptions explicit, minimal surgical changes, root-cause fixes, verification discipline, fail loud, routing table |
| delivery | Complex delivery: task packet (spec/task/review), executable acceptance checks, gate, independent review, loop-ready exit |
| reviewit | Accepting an agent's output: deterministic checks first, role-aware write protocol (embedded → review.md only) |
| handoff | Session-compaction handover (cross-session / cross-agent) |
| bootstrap | Repo cold-start: scan the repo → generate STATE.md + lessons + a real-command gate (gate.sh / gate.ps1 by environment) and run it to verify |
| grilling / grill-me / grill-with-docs | The human-side interrogation engine + two thin entry points |
| domain-modeling | Glossary (CONTEXT.md) + ADR discipline |
| diagnosing-bugs | Hard bugs: red-light loop first, no hypothesis without a reproduction command |
| resolving-merge-conflicts | Resolve hunk by hunk per both sides' intent, never --abort |
| writing-great-skills | The meta-theory of writing/editing skills (leading words, no-op test, dual-payload model) |

`agents/reviewer.md`: a read-only acceptance agent whose tool whitelist carries no edit capability — maker/checker separation enforced by permission, not by exhortation.

Measured component list and token cost (`claude plugin details agent-playbook`):

```text
Skills (12)  bootstrap, delivery, diagnosing-bugs, domain-modeling, grill-me, grill-with-docs,
             grilling, groundwork, handoff, resolving-merge-conflicts, reviewit,
             writing-great-skills
Agents (1)   reviewer
Hooks (0)
Always-on:   ~1,096 tok   added to every session
```

## Quick Start

### Claude Code

```
claude plugin marketplace add Wsr-7/agent-playbook
claude plugin install agent-playbook@agent-playbook
```

A private repo needs access granted to collaborators first. Skills trigger automatically on matching requests, and can also be invoked manually: `/groundwork`, `/delivery`. Local-path install: `claude --plugin-dir "path/to/agent-playbook"`.

### Codex CLI

```
codex plugin marketplace add Wsr-7/agent-playbook
codex plugin add agent-playbook@agent-playbook
```

Trigger with `/skill-name` or `$skill-name` (e.g. `/reviewit`, `$reviewit`), or just describe the task and let Codex pick. (`@skill-name` only works for standalone skills placed directly at the top level of `~/.codex/skills/`; this plugin is installed via `plugin add` and is not on that search path, so `@` won't find it.) Reviews go to `reviewit`: Codex's independent review is realized through a read-only review skill (its built-in `review-agent` is exactly this shape), and reviewit fills that role. The repo-root `agents/reviewer.md` is a Claude-Code-only persona — it locks read-only from the permission layer via a tool whitelist, a Claude-Code-specific reinforcement; Codex does not load it and does not need it, since reviewit already covers the review duty.

### OpenCode

Copy the skill directories you want from `skills/` into your project's `.opencode/skills/`, or create symlinks there pointing at the corresponding skill directories in this repo — one folder per skill (with its `SKILL.md` and attached files) is all it needs.

### GitHub Copilot

Copilot scans one of `.github/skills`, `.claude/skills`, `.agents/skills`. Copy the skill directories you want from `skills/` into any one of them; `.github/skills` is recommended when there's no existing directory. The agent persona needs separate handling: the filename must end in `.agent.md` (a plain `.md` is silently ignored). This repo ships `.github/agents/reviewer.agent.md`; call it in Copilot Chat with `@reviewer`.

### Other agents

Check the agent's docs for which skills directory it scans (many tools also honor the common location `.agents/skills/`), then copy or symlink the skill directories you want from `skills/` there — one self-contained folder per skill, depending on nothing else in the repo.

### Make groundwork the default baseline (optional)

groundwork's description (and every other skill's) ships with the plugin, so the model auto-loads it on matching coding tasks — installed means active, no extra config. The "(auto) groundwork applies" in the workflow map relies on exactly this mechanism.

For a stronger guarantee than the model's own judgment ("every coding task must start on groundwork"), add this to your `CLAUDE.md` or `AGENTS.md`:

```markdown
When a task involves writing, reviewing, or refactoring code, load the
`groundwork` skill before starting — it carries the baseline judgment
rules (minimal change, root-cause fixes, verification discipline) the
other skills build on.
```

This repo deliberately avoids a SessionStart hook for global forced injection: groundwork is only needed while coding, and SessionStart cannot tell task types apart at session start, so forced injection would make non-coding sessions pay the token cost too. Whether to add that reinforcement is left to the user's own preference.

## Project-side companions (templates/)

Skills are general conventions; each project still needs landing pieces (copy the template, then adjust to the project):

- `templates/gate.sh` (Unix/macOS) / `templates/gate.ps1` (Windows) → the project's `scripts/gate.*`: a deterministic acceptance gate (tests / build / git state) that reviewit and delivery find and run first. Use the one matching your project's shell environment.
- `templates/STATE.md` → project root or local docs dir: the loop state file recording in-progress / done / awaiting-human-verification / lessons.
- `templates/hooks/inject-state.ps1` → `~/.claude/hooks/`: a SessionStart hook that force-injects the project STATE.md at session start (install instructions in the file header) — forced injection beats hoping the model reads it. This hook is **not** installed automatically with the plugin: it fires on every session of every project, which is a user-level decision, so install it by hand.

A hook is an optional enhancement, not a dependency: on platforms without hooks, groundwork's start-of-work rule provides a prose fallback (read STATE.md and lessons before starting) — probabilistic but usually effective; platforms that support hooks upgrade to deterministic injection once installed. Every skill is fully functional in a hook-free environment. Same for the reviewer agent: platforms without a custom-agent capability fall back to the prose reviewer brief in delivery §7.

Fastest path to onboard a new project: after installing the plugin, say `/bootstrap` in the project — the three companions are generated and the gate is run to verify.

## Credits

- grilling, grill-me, grill-with-docs, domain-modeling, diagnosing-bugs, resolving-merge-conflicts, handoff, writing-great-skills come from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT), some with modifications (narrowed trigger words, dangling-reference fixes, portability adjustments).
- groundwork fuses the essence of karpathy's coding rules, the survival clauses of ai-coding-agent-guidelines, and the minimalist ladder of [ponytail](https://github.com/DietrichGebert/ponytail).
- The multi-platform plugin manifest structure references the real implementations of [ponytail](https://github.com/DietrichGebert/ponytail) and [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).
- The workflow design draws on the Anthropic Claude Code team's practice around loop engineering (gate, state file, maker/checker separation, hard stops), with some ideas borrowed from [Trellis](https://github.com/mindfold-ai/Trellis) (state-injection hook, cold start, spec-promotion loop).

## License

MIT, see [LICENSE](LICENSE).

---

<a id="zh"></a>

# agent-playbook（简体中文）

[English](#agent-playbook) · **简体中文**

一套根据个人工作习惯和经验沉淀的 AI coding-agent playbook：一条从需求拷问到交付验收的完整链路。出发点是去掉 superpowers 这类重型框架的约束，只保留在强模型时代仍改变行为的部分，再吸收不同优秀 skill / plugin 的思想为己所用——既有自己的沉淀（如 delivery、reviewit、gate 体系），也有直接照搬并按需改造的成熟 skill（如源自 mattpocock 的 grilling 系列）。

## 目录

- [设计哲学](#zh-philosophy)
- [全流程地图](#zh-map)
- [Skill 清单](#zh-skills)
- [Quick Start](#zh-quickstart)
- [项目侧配套](#zh-templates)
- [来源与致谢](#zh-credits)
- [License](#zh-license)

<a id="zh-philosophy"></a>

## 设计哲学

强模型已经内化了大部分"流程知识"（怎么做 TDD、怎么写计划），所以本仓库不教流程。每条规则入选前都要过三问检验：

1. **模型知道怎么做吗？** 知道的 → 不写（会被内化，写了是浪费 token 的 no-op）
2. **模型默认会去做吗？** 知道但默认不做的（反默认纪律）→ **写**
3. **信息在谁手里？** 在人脑里的（决策、seam 取舍、验收时机）→ **写成向人提问/确认的协议**

四条派生原则：

- **Gate 优先于意见**：验收先跑确定性检查（exit code），模型判断只覆盖脚本查不了的部分。"A reviewer without a gate is a second optimist."
- **主心骨 + 挂靠引擎**：groundwork 永远在场，专业引擎按需触发，引用不内联。
- **有意的少量重复**：核心行为规则在引擎间刻意重复几行，使每个 skill 文件可独立分发——拿走任何一个都自洽，不依赖本仓库其他文件、任何插件或个人配置。**维护时请勿"好心去重"。**
- **skill 正文保持平台无关**：触发前缀、平台差异（`/name` vs `$name`、hook、agent persona 等）放 README 或平台专属文件（如 `agents/openai.yaml`），不进 `SKILL.md` 正文——正文是可跨平台分发的工作流指令，塞平台细节就是污染。

<a id="zh-map"></a>

## 全流程地图

```text
任务进来
├─ (自动) groundwork 生效：判断力基线垫底
├─ 需求模糊？        → /grill-me 逐分支拷问（要留术语表/ADR 用 /grill-with-docs）
├─ 大任务？          → /delivery：spec 冻结 → 计划 → 实现(小步 checkpoint commit)
│                      → gate 脚本 → 独立审查(≤2轮) → 交付报告
├─ 卡硬 bug？        → (自动) diagnosing-bugs：先造红灯命令，再谈假设
├─ 验收 agent 产出？ → /reviewit：gate 先跑 → 判断性审查 → 人工验证表
├─ 会话要断/换端？   → /handoff
└─ git 冲突？        → (自动) resolving-merge-conflicts
```

一句话记忆：**groundwork 无处不在，grill 在动手前，delivery 在做大事，diagnose 在卡死时，review 在收货时，handoff 在离场时。**

<a id="zh-skills"></a>

## Skill 清单

| Skill | 角色 |
| --- | --- |
| groundwork | 行为基线：假设显式化、最小手术式改动、根因修复、验证纪律、fail loud、路由表 |
| delivery | 复杂交付：task packet(spec/task/review)、可执行验收标准、gate、独立审查、循环化出口 |
| reviewit | 验收 agent 产出：确定性检查先行，双角色写入协议（嵌入式只写 review.md） |
| handoff | 会话压缩交接（跨会话/跨 agent） |
| bootstrap | 项目冷启动：扫描仓库 → 生成 STATE.md + lessons + 真实命令版 gate 脚本（gate.sh / gate.ps1 按环境选）并实跑验证 |
| grilling / grill-me / grill-with-docs | 人侧拷问引擎 + 两个薄入口 |
| domain-modeling | 术语表(CONTEXT.md) + ADR 纪律 |
| diagnosing-bugs | 硬 bug：红灯循环优先，无复现命令不许提假设 |
| resolving-merge-conflicts | 按双方意图逐 hunk 解决，never --abort |
| writing-great-skills | 写/改 skill 的元理论（leading words、no-op 检验、双负载模型） |

`agents/reviewer.md`：只读验收 agent，工具白名单不含编辑能力，maker/checker 分离由权限而非嘱咐保证。

实测组件清单与 token 成本（`claude plugin details agent-playbook`）：

```text
Skills (12)  bootstrap, delivery, diagnosing-bugs, domain-modeling, grill-me, grill-with-docs,
             grilling, groundwork, handoff, resolving-merge-conflicts, reviewit,
             writing-great-skills
Agents (1)   reviewer
Hooks (0)
Always-on:   ~1,096 tok   added to every session
```

<a id="zh-quickstart"></a>

## Quick Start

### Claude Code

```
claude plugin marketplace add Wsr-7/agent-playbook
claude plugin install agent-playbook@agent-playbook
```

私有仓库需先给协作者开访问权限。skill 会在匹配的请求上自动触发，也可手动调用：`/groundwork`、`/delivery`。本地路径安装：`claude --plugin-dir "path/to/agent-playbook"`。

### Codex CLI

```
codex plugin marketplace add Wsr-7/agent-playbook
codex plugin add agent-playbook@agent-playbook
```

用 `/skill-name` 或 `$skill-name` 触发（如 `/reviewit`、`$reviewit`），或直接描述任务让 Codex 自行选择。（`@skill-name` 只对直接放进 `~/.codex/skills/` 顶层的独立 skill 有效；本插件通过 `plugin add` 安装、不在该搜索路径，用 `@` 找不到。）审查交给 `reviewit`：Codex 的独立审查靠只读审查 skill 实现（其内置的 `review-agent` 即是此形态），reviewit 正是这个角色。仓库根的 `agents/reviewer.md` 是 Claude Code 专用 persona——用工具白名单从权限层锁死只读，这是 Claude Code 独有的加强；Codex 不加载它，也不需要，reviewit 已覆盖审查职责。

### OpenCode

把 `skills/` 下需要的 skill 目录复制到项目的 `.opencode/skills/`，或在其中创建指向本仓库对应 skill 目录的符号链接——每个 skill 一个文件夹（连同它的 `SKILL.md` 与附属文件）即可。

### GitHub Copilot

Copilot 扫描 `.github/skills`、`.claude/skills`、`.agents/skills` 三者之一。把 `skills/` 下需要的 skill 目录复制到其中任一位置即可，没有现成目录时推荐 `.github/skills`。agent persona 需单独处理：文件名必须以 `.agent.md` 结尾（普通 `.md` 会被静默忽略），本仓库提供 `.github/agents/reviewer.agent.md`，在 Copilot Chat 里用 `@reviewer` 调用。

### 其他 agent

查该 agent 文档确认它扫描的 skills 目录位置（不少工具也认通用位置 `.agents/skills/`），把 `skills/` 下需要的 skill 目录复制或软链过去即可——每个 skill 一个自包含文件夹，不依赖仓库其他文件。

### 让 groundwork 默认垫底（可选）

groundwork 及其余 skill 的 description 随插件分发，模型会在匹配的编码任务上自动加载它——装了插件即生效，无需任何额外配置。全流程地图里"(自动) groundwork 生效"依赖的就是这个机制。

若想要"每次编码任务必以 groundwork 垫底"的更强保证（而非依赖模型自主判断），把这段加进你的 `CLAUDE.md` 或 `AGENTS.md`：

```markdown
When a task involves writing, reviewing, or refactoring code, load the
`groundwork` skill before starting — it carries the baseline judgment
rules (minimal change, root-cause fixes, verification discipline) the
other skills build on.
```

本仓库刻意不用 SessionStart hook 做全局强制注入：groundwork 只在编码时需要，而 SessionStart 在会话开始时无法区分任务类型，强制注入会让非编码会话也付出 token 成本。是否要这层强化，交给使用者按自己的偏好决定。

<a id="zh-templates"></a>

## 项目侧配套（templates/）

skill 是通用约定，每个项目还需落地件（复制模板后按项目改）：

- `templates/gate.sh`（Unix/macOS）/ `templates/gate.ps1`（Windows）→ 项目的 `scripts/gate.*`：确定性验收门（测试/构建/git 状态），reviewit 和 delivery 会自动找到并优先执行它；按项目 shell 环境选用对应版本
- `templates/STATE.md` → 项目根或本地文档目录：循环状态文件，记录进行中/已完成/待人工验证/lessons
- `templates/hooks/inject-state.ps1` → `~/.claude/hooks/`：SessionStart hook，会话启动时强制注入项目 STATE.md（安装方式见文件头注释）——强制注入优于指望模型自觉去读。这个 hook **不**随插件自动安装：它会在每个项目的每次会话触发，属于用户级决定，需手动装

Hook 是可选增强，不是依赖：平台不支持 hooks 时，groundwork 的开工规则会以 prose 方式兜底（开工先读 STATE.md 和 lessons）——概率性但通常有效；支持 hooks 的平台装上后升级为确定性注入。所有 skill 在无 hook 环境下功能完整。reviewer agent 同理：无自定义 agent 能力的平台退回 delivery §7 的 prose 版 reviewer brief。

新项目接入最快路径：装好插件后在项目里说 `/bootstrap`，三件套自动生成并实跑 gate 验证。

<a id="zh-credits"></a>

## 来源与致谢

- grilling、grill-me、grill-with-docs、domain-modeling、diagnosing-bugs、resolving-merge-conflicts、handoff、writing-great-skills 源自 [mattpocock/skills](https://github.com/mattpocock/skills)（MIT），部分经过修改（触发词收窄、悬空引用修复、可移植性调整）
- groundwork 融合了 karpathy 编码守则、ai-coding-agent-guidelines 的存活条款与 [ponytail](https://github.com/DietrichGebert/ponytail) 极简主义阶梯的精华
- 多平台插件清单结构参考了 [ponytail](https://github.com/DietrichGebert/ponytail) 与 [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 的真实实现
- 工作流设计参考 Anthropic Claude Code 团队关于 loop engineering 的实践（gate、state file、maker/checker 分离、硬停止），部分理念借鉴自 [Trellis](https://github.com/mindfold-ai/Trellis)（状态注入 hook、冷启动、spec 晋升闭环）

<a id="zh-license"></a>

## License

MIT，见 [LICENSE](LICENSE)。
