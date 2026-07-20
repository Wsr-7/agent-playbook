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
.claude-plugin/{marketplace.json,plugin.json}   Claude Code
.codex-plugin/plugin.json                        Codex CLI（marketplace.json 与 Claude Code 共用）
.github/plugin/{marketplace.json,plugin.json}     GitHub Copilot CLI
.agents/plugins/marketplace.json                  跨工具通用清单位置
.opencode/skills -> ../skills                     OpenCode（符号链接，非复制）
```

平台读到清单后自己克隆/缓存仓库、自己发现 `skills/` 和 `agents/` 目录下的内容、自己管理版本更新——不需要任何同步脚本，不需要手动复制文件。这是这套生态（对比 [ponytail](https://github.com/DietrichGebert/ponytail)、[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 等已发布插件验证过）的标准做法，比手写脚本复制文件更可靠、更好维护。

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

装好后用 `$groundwork`、`$delivery` 等触发（Codex 用 `$` 前缀，Claude Code 用 `/`）。本地路径同样可用：`codex plugin marketplace add "path/to/agent-playbook"`。

### OpenCode

仓库内 `.opencode/skills` 是指向 `../skills` 的符号链接（架构参考 addyosmani/agent-skills 的验证实现）。克隆仓库到项目内或作为 OpenCode 能发现的路径即可；命令语法与具体触发方式请对照 OpenCode 当前文档确认——本仓库未装 OpenCode CLI 做端到端安装测试，结构正确性以静态验证（git 符号链接、真实指向 `skills/`）为准，实际加载行为请自行验证一次。

### GitHub Copilot CLI

`.github/plugin/{marketplace.json,plugin.json}` 镜像了 Claude Code 清单的结构（参考 ponytail 的真实实现）。本机未装 `copilot` CLI，这份清单**未经端到端测试**，仅结构上遵循已知可用的约定。

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
- 插件清单结构（marketplace.json/plugin.json 多平台约定、OpenCode 符号链接模式）参考了 [ponytail](https://github.com/DietrichGebert/ponytail) 与 [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 的真实实现
- 工作流设计参考 Anthropic Claude Code 团队关于 loop engineering 的实践（gate、state file、maker/checker 分离、硬停止），部分理念借鉴自 [Trellis](https://github.com/mindfold-ai/Trellis)（状态注入 hook、冷启动、spec 晋升闭环）

## License

MIT，见 [LICENSE](LICENSE)。
