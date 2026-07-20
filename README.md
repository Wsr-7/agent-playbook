# agent-playbook

一套根据个人工作习惯和经验沉淀的 AI coding-agent playbook：一条从需求拷问到交付验收的完整链路。出发点是去掉 superpowers 这类重型框架的约束，只保留在强模型时代仍改变行为的部分，再吸收不同优秀 skill / plugin 的思想为己所用——既有自己的沉淀（如 delivery、review-worker、gate 体系），也有直接照搬并按需改造的成熟 skill（如源自 mattpocock 的 grilling 系列）。

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

用 `@skill-name` 触发（如 `@groundwork`），或直接描述任务让 Codex 自行选择。Codex 不支持 agent persona——`agents/reviewer.md` 会随插件进入缓存，但无法作为子 agent 调用；需要审查时直接触发 `review-worker` skill。

### OpenCode

`.opencode/skills`（符号链接指向 `skills/`）由 OpenCode 内置的 `skill` 工具原生发现，无需任何配置。克隆仓库使该目录能被项目访问即可。

### GitHub Copilot

Copilot 扫描 `.github/skills`、`.claude/skills`、`.agents/skills` 三者之一，本仓库提供 `.github/skills`。agent persona 文件名必须以 `.agent.md` 结尾——普通 `.md` 会被静默忽略。`.github/agents/reviewer.agent.md` 遵循此约定，在 Copilot Chat 里用 `@reviewer` 调用。

### 其他 agent

没有专属清单也能用：克隆仓库，把需要的 `skills/<name>/SKILL.md` 内容贴进 agent 的系统提示词、规则文件（如 `CLAUDE.md`/`.cursorrules`）或直接粘进对话——每份 SKILL.md 都是自包含的纯 Markdown，不依赖仓库其他文件。

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

## 项目侧配套（templates/）

skill 是通用约定，每个项目还需落地件（复制模板后按项目改）：

- `templates/gate.ps1` → 项目的 `scripts/gate.ps1`：确定性验收门（测试/构建/git 状态），review-worker 和 delivery 会自动找到并优先执行它
- `templates/STATE.md` → 项目根或本地文档目录：循环状态文件，记录进行中/已完成/待人工验证/lessons
- `templates/hooks/inject-state.ps1` → `~/.claude/hooks/`：SessionStart hook，会话启动时强制注入项目 STATE.md（安装方式见文件头注释）——强制注入优于指望模型自觉去读。这个 hook **不**随插件自动安装：它会在每个项目的每次会话触发，属于用户级决定，需手动装

Hook 是可选增强，不是依赖：平台不支持 hooks 时，groundwork 的开工规则会以 prose 方式兜底（开工先读 STATE.md 和 lessons）——概率性但通常有效；支持 hooks 的平台装上后升级为确定性注入。所有 skill 在无 hook 环境下功能完整。reviewer agent 同理：无自定义 agent 能力的平台退回 delivery §7 的 prose 版 reviewer brief。

新项目接入最快路径：装好插件后在项目里说 `/bootstrap`，三件套自动生成并实跑 gate 验证。

## 来源与致谢

- grilling、grill-me、grill-with-docs、domain-modeling、diagnosing-bugs、resolving-merge-conflicts、handoff、writing-great-skills 源自 [mattpocock/skills](https://github.com/mattpocock/skills)（MIT），部分经过修改（触发词收窄、悬空引用修复、可移植性调整）
- groundwork 融合了 karpathy 编码守则、ai-coding-agent-guidelines 的存活条款与 [ponytail](https://github.com/DietrichGebert/ponytail) 极简主义阶梯的精华
- 多平台插件清单结构参考了 [ponytail](https://github.com/DietrichGebert/ponytail) 与 [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 的真实实现
- 工作流设计参考 Anthropic Claude Code 团队关于 loop engineering 的实践（gate、state file、maker/checker 分离、硬停止），部分理念借鉴自 [Trellis](https://github.com/mindfold-ai/Trellis)（状态注入 hook、冷启动、spec 晋升闭环）

## License

MIT，见 [LICENSE](LICENSE)。
