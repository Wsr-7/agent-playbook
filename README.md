# agent-playbook

个人 AI coding-agent playbook：一条从需求拷问到交付验收的完整链路。以 skill 为主体，跨 Claude Code、Codex CLI、OpenCode、GitHub Copilot CLI 分发。

## 设计哲学

强模型已经内化了大部分"流程知识"（怎么做 TDD、怎么写计划），所以本仓库不教流程。每条规则入选前都要过三问检验：

1. **模型知道怎么做吗？** 知道的 → 不写（会被内化，写了是浪费 token 的 no-op）
2. **模型默认会去做吗？** 知道但默认不做的（反默认纪律）→ **写**
3. **信息在谁手里？** 在人脑里的（决策、seam 取舍、验收时机）→ **写成向人提问/确认的协议**

三条派生原则：

- **Gate 优先于意见**：验收先跑确定性检查（exit code），模型判断只覆盖脚本查不了的部分。"A reviewer without a gate is a second optimist."
- **主心骨 + 挂靠引擎**：groundwork 永远在场，专业引擎按需触发，引用不内联。
- **有意的少量重复**：核心行为规则在引擎间刻意重复几行，使每个 skill 文件可独立分发——拿走任何一个都自洽，不依赖本仓库其他文件、任何插件或个人配置。**维护时请勿"好心去重"。**

## 全流程地图

```text
任务进来
├─ (自动) groundwork 生效：判断力基线垫底
├─ 需求模糊？        → /grill-me 逐分支拷问（要留术语表/ADR 用 /grill-with-docs）
├─ 大任务？          → /delivery：spec 冻结 → 计划 → 实现(小步 checkpoint commit)
│                      → gate 脚本 → 独立审查(≤2轮) → 交付报告
├─ 卡硬 bug？        → (自动) diagnosing-bugs：先造红灯命令，再谈假设
├─ 验收 agent 产出？ → /review-worker：gate 先跑 → 判断性审查 → 人工验证表
├─ 会话要断/换端？   → /handoff
└─ git 冲突？        → (自动) resolving-merge-conflicts
```

一句话记忆：**groundwork 无处不在，grill 在动手前，delivery 在做大事，diagnose 在卡死时，review 在收货时，handoff 在离场时。**

## Skill 清单

| Skill | 角色 |
| --- | --- |
| groundwork | 行为基线：假设显式化、最小手术式改动、根因修复、验证纪律、fail loud、路由表 |
| delivery | 复杂交付：task packet(spec/task/review)、可执行验收标准、gate、独立审查、循环化出口 |
| review-worker | 验收 agent 产出：确定性检查先行，双角色写入协议（嵌入式只写 review.md） |
| handoff | 会话压缩交接（跨会话/跨 agent） |
| bootstrap | 项目冷启动：扫描仓库 → 生成 STATE.md + lessons + 真实命令版 gate.ps1 并实跑验证 |
| grilling / grill-me / grill-with-docs | 人侧拷问引擎 + 两个薄入口 |
| domain-modeling | 术语表(CONTEXT.md) + ADR 纪律 |
| diagnosing-bugs | 硬 bug：红灯循环优先，无复现命令不许提假设 |
| resolving-merge-conflicts | 按双方意图逐 hunk 解决，never --abort |
| writing-great-skills | 写/改 skill 的元理论（leading words、no-op 检验、双负载模型） |

`agents/reviewer.md`：只读验收 agent，工具白名单不含编辑能力，maker/checker 分离由权限而非嘱咐保证。

实测组件清单与 token 成本（`claude plugin details agent-playbook`）：

```text
Skills (12)  bootstrap, delivery, diagnosing-bugs, domain-modeling, grill-me, grill-with-docs,
             grilling, groundwork, handoff, resolving-merge-conflicts, review-worker,
             writing-great-skills
Agents (1)   reviewer
Hooks (0)
Always-on:   ~1,096 tok   added to every session
```

## 为什么是一个"插件"

`skills/` 是唯一真身；仓库根目录另外放了几份小清单文件，每份只做一件事——告诉某个平台"我的 skills 在哪、我的 agents 在哪"：

```text
.claude-plugin/{marketplace.json,plugin.json}   Claude Code — 插件市场机制，克隆+缓存+自动发现
.codex-plugin/plugin.json                        Codex CLI — 同上（marketplace.json 与 Claude Code 共用）
.agents/plugins/marketplace.json                  跨工具通用清单位置（Codex 也会读）
.opencode/skills -> ../skills                     OpenCode — 符号链接，配合 AGENTS.md 的 skill 工具使用
.github/skills -> ../skills                       GitHub Copilot — 符号链接，Copilot 直接扫描该目录
.github/agents/reviewer.agent.md -> ...            GitHub Copilot 的 agent persona（文件名必须以 .agent.md 结尾）
```

两种机制并存：Claude Code 和 Codex 有真正的插件市场（清单声明 + CLI 自动克隆缓存 + 版本管理）；OpenCode 和 Copilot **没有**插件系统，靠约定路径的目录直接扫描——所以那两个是符号链接指向同一份 `skills/`，不是另一套清单。这套模式验证自两个已发布的真实插件仓库：[ponytail](https://github.com/DietrichGebert/ponytail)（Claude Code/Codex 清单）、[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)（本仓库对每个平台的真实机制均以其 [docs/](https://github.com/addyosmani/agent-skills/tree/main/docs) 下的官方安装指南为准，而非从目录结构反推）。

## 安装与使用

### Claude Code（已实测验证）

```
claude plugin marketplace add Wsr-7/agent-playbook
claude plugin install agent-playbook@agent-playbook
```

私有仓库需要先给协作者开 GitHub 访问权限。装好后按需触发：说话涉及某个 skill 的 description 场景时自动加载，或手动输入 `/groundwork`、`/delivery` 等命令。

本地开发/未推送验证过（无需发布即可试用）：

```powershell
claude --plugin-dir "path/to/agent-playbook" plugin details agent-playbook   # 查看组件清单与 token 成本
claude --plugin-dir "path/to/agent-playbook"                                  # 会话内一次性启用
```

### Codex CLI（已实测验证）

```
codex plugin marketplace add Wsr-7/agent-playbook
codex plugin add agent-playbook@agent-playbook
```

装好后用 `@skill-name` 触发（如 `@groundwork`），或直接描述任务让 Codex 自己选。**限制**：Codex 对 agent persona 没有原生支持——`agents/reviewer.md` 会随插件装进缓存，但不会被当作可调用的子 agent；需要审查时直接触发 `review-worker` skill 本身即可，它不依赖 reviewer agent 才能工作。本地路径同样可用：`codex plugin marketplace add "path/to/agent-playbook"`。

### OpenCode

OpenCode **没有原生插件系统或自动 skill 路由**——这不是我们的限制，是 OpenCode 本身的限制（官方文档原话）。真正让 skill 被使用的是两样东西：`skills/` 目录本身（仓库已通过 `.opencode/skills -> ../skills` 符号链接提供），加上一份指示 agent "遇事先查 skill、调用内置 `skill` 工具"的 `AGENTS.md`。后者需要你在自己项目的 `AGENTS.md` 里补一段（没有就新建）：

```markdown
## Skill usage (agent-playbook)

Skills live in `skills/<name>/SKILL.md` (symlinked from this plugin). Before
acting on a non-trivial request, check whether a skill applies and invoke it
via the `skill` tool — don't skip straight to implementation.

- Any coding task → `groundwork` (check this first)
- Requirements unclear → `grilling` (or `grill-with-docs` for a glossary trail)
- Complex/multi-agent delivery → `delivery`
- Hard or recurring bug → `diagnosing-bugs`
- Accepting another agent's work → `review-worker`
- Merge/rebase conflict → `resolving-merge-conflicts`
```

没有这段 `AGENTS.md` 指令，符号链接只是让文件存在，不代表会被用到——skill 是否触发依赖模型是否遵循这段指令，不是平台强制的。本机未装 OpenCode CLI 做端到端验证，机制描述来自 OpenCode 官方设置文档，未经本仓库实测确认。

### GitHub Copilot

Copilot 不是插件市场机制，而是直接扫描约定路径的目录——`.github/skills`、`.claude/skills`、`.agents/skills` 三选一（[官方文档](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-skills)）。本仓库提供 `.github/skills -> ../skills` 符号链接。

Agent persona 需要单独处理：Copilot 要求文件名以 **`.agent.md`** 结尾，普通 `.md` 会被静默忽略——本仓库提供 `.github/agents/reviewer.agent.md`（指向 `agents/reviewer.md` 的符号链接）。Copilot Chat 里用 `@reviewer` 调用。

想要项目级常驻指令（不依赖 skill 触发），Copilot 支持 `.github/copilot-instructions.md`——这个仓库目前没提供，属于"你自己项目要不要采纳"的选择，不强加。

本机未装 `copilot` CLI，以上机制未经端到端测试，结构与命名规则均来自官方文档与 addyosmani/agent-skills 的验证实现。

### 其他平台

克隆仓库后把 `skills/` 下的目录按平台约定复制到对应的 skills 目录即可——每个 SKILL.md 都是自包含的纯 Markdown，不依赖仓库其他文件。

## 项目侧配套（templates/）

skill 是通用约定，每个项目还需落地件（复制模板后按项目改）：

- `templates/gate.ps1` → 项目的 `scripts/gate.ps1`：确定性验收门（测试/构建/git 状态），review-worker 和 delivery 会自动找到并优先执行它
- `templates/STATE.md` → 项目根或本地文档目录：循环状态文件，记录进行中/已完成/待人工验证/lessons
- `templates/hooks/inject-state.ps1` → `~/.claude/hooks/`：SessionStart hook，会话启动时强制注入项目 STATE.md（安装方式见文件头注释）——强制注入优于指望模型自觉去读。这个 hook **不**随插件自动安装：它会在每个项目的每次会话触发，属于用户级决定，需手动装

Hook 是可选增强，不是依赖：平台不支持 hooks 时，groundwork 的开工规则会以 prose 方式兜底（开工先读 STATE.md 和 lessons）——概率性但通常有效；支持 hooks 的平台装上后升级为确定性注入。所有 skill 在无 hook 环境下功能完整。reviewer agent 同理：无自定义 agent 能力的平台退回 delivery §7 的 prose 版 reviewer brief。

新项目接入最快路径：装好插件后在项目里说 `/bootstrap`，三件套自动生成并实跑 gate 验证。

## 进化触发器（记录在案，触发前不做）

- 项目 CLAUDE.md 超过约 200 行、或不同模块的约定开始互相冲突 → 参考 Trellis 的 spec 树：按模块拆分域规范，按需注入
- 并行任务多到 STATE.md 手工维护吃力 → 再评估任务状态机（这是引入运行时脚本依赖的唯一正当理由）
- 需要独立的斜杠命令层（`/build` `/plan` `/test` 等，参考 addyosmani/agent-skills 的 commands/ 设计）→ 当前用 skill 自动触发 + `/skill-name` 已覆盖同等能力，重复了才值得加
- Gemini CLI 或其他平台出现真实使用需求 → 再补对应清单，不预先占位

## 来源与致谢

- grilling、grill-me、grill-with-docs、domain-modeling、diagnosing-bugs、resolving-merge-conflicts、handoff、writing-great-skills 源自 [mattpocock/skills](https://github.com/mattpocock/skills)（MIT），部分经过修改（触发词收窄、悬空引用修复、可移植性调整）
- groundwork 融合了 karpathy 编码守则、ai-coding-agent-guidelines 的存活条款与 [ponytail](https://github.com/DietrichGebert/ponytail) 极简主义阶梯的精华
- Claude Code / Codex 的插件清单结构参考 [ponytail](https://github.com/DietrichGebert/ponytail) 的真实实现；`.agents` 通用清单写法、OpenCode 与 GitHub Copilot 的接入机制（均无原生插件系统，前者靠 `AGENTS.md` + `skill` 工具、后者靠约定路径目录扫描 + `.agent.md` 命名规则）来自 [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 的 [docs/](https://github.com/addyosmani/agent-skills/tree/main/docs) 官方设置指南——本仓库均以其文档为准，OpenCode/Copilot 机制未经本地 CLI 端到端测试
- 工作流设计参考 Anthropic Claude Code 团队关于 loop engineering 的实践（gate、state file、maker/checker 分离、硬停止），部分理念借鉴自 [Trellis](https://github.com/mindfold-ai/Trellis)（状态注入 hook、冷启动、spec 晋升闭环）

## License

MIT，见 [LICENSE](LICENSE)。
