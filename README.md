# wsr-skills

强模型时代的个人 AI-coding skills 合集：一条从需求拷问到交付验收的完整链路，跨 Claude Code 与 Codex CLI 单源分发。

## 设计哲学

强模型已经内化了大部分"流程知识"（怎么做 TDD、怎么写计划），所以本仓库不教流程。每条规则入选前都要过三问检验：

1. **模型知道怎么做吗？** 知道的 → 不写（会被内化，写了是浪费 token 的 no-op）
2. **模型默认会去做吗？** 知道但默认不做的（反默认纪律）→ **写**
3. **信息在谁手里？** 在人脑里的（决策、seam 取舍、验收时机）→ **写成向人提问/确认的协议**

三条派生原则：

- **Gate 优先于意见**：验收先跑确定性检查（exit code），模型判断只覆盖脚本查不了的部分。"A reviewer without a gate is a second optimist."
- **主心骨 + 挂靠引擎**：spine 永远在场，专业引擎按需触发，引用不内联。
- **有意的少量重复**：核心行为规则在引擎间刻意重复几行，使每个 skill 文件可独立分发——拿走任何一个都自洽，不依赖本仓库其他文件、任何插件或个人配置。**维护时请勿"好心去重"。**

## 全流程地图

```text
任务进来
├─ (自动) spine 生效：判断力基线垫底
├─ 需求模糊？        → /grill-me 逐分支拷问（要留术语表/ADR 用 /grill-with-docs）
├─ 大任务？          → /ship：spec 冻结 → 计划 → 实现(小步 checkpoint commit)
│                      → gate 脚本 → 独立审查(≤2轮) → 交付报告
├─ 卡硬 bug？        → (自动) diagnosing-bugs：先造红灯命令，再谈假设
├─ 验收 agent 产出？ → /review-worker：gate 先跑 → 判断性审查 → 人工验证表
├─ 会话要断/换端？   → /handoff
└─ git 冲突？        → (自动) resolving-merge-conflicts
```

一句话记忆：**spine 无处不在，grill 在动手前，ship 在做大事，diagnose 在卡死时，review 在收货时，handoff 在离场时。**

## Skill 清单

| 类别 | Skill | 角色 |
| --- | --- | --- |
| core | spine | 行为基线：假设显式化、最小手术式改动、根因修复、验证纪律、fail loud、路由表 |
| workflow | ship | 复杂交付：task packet(spec/task/review)、可执行验收标准、gate、独立审查、循环化出口 |
| workflow | review-worker | 验收 agent 产出：确定性检查先行，双角色写入协议（嵌入式只写 review.md） |
| workflow | handoff | 会话压缩交接（跨会话/跨 agent） |
| workflow | bootstrap | 项目冷启动：扫描仓库 → 生成 STATE.md + lessons + 真实命令版 gate.ps1 并实跑验证 |
| elicitation | grilling / grill-me / grill-with-docs | 人侧拷问引擎 + 两个薄入口 |
| elicitation | domain-modeling | 术语表(CONTEXT.md) + ADR 纪律 |
| debugging | diagnosing-bugs | 硬 bug：红灯循环优先，无复现命令不许提假设 |
| git | resolving-merge-conflicts | 按双方意图逐 hunk 解决，never --abort |
| meta | writing-great-skills | 写/改 skill 的元理论（leading words、no-op 检验、双负载模型） |

## 安装

```powershell
git clone <this-repo>
cd wsr-skills
pwsh -NoProfile -File sync.ps1          # 同步到 ~/.claude/skills 和 ~/.codex/skills
pwsh -NoProfile -File sync.ps1 -Target claude   # 只同步一端
```

本仓库是唯一事实源：改动只发生在这里，改完跑 `sync.ps1` 分发。不要直接编辑 `~/.claude/skills` 或 `~/.codex/skills` 下的副本。

## 项目侧配套（templates/）

skill 是通用约定，每个项目还需两个落地件（复制模板后按项目改）：

- `templates/gate.ps1` → 项目的 `scripts/gate.ps1`：确定性验收门（测试/构建/git 状态），review-worker 和 ship 会自动找到并优先执行它
- `templates/STATE.md` → 项目根或本地文档目录：循环状态文件，记录进行中/已完成/待人工验证/lessons
- `templates/hooks/inject-state.ps1` → `~/.claude/hooks/`：SessionStart hook，会话启动时强制注入项目 STATE.md（安装方式见文件头注释）——强制注入优于指望模型自觉去读

新项目接入最快路径：装好 skills 后在项目里说 `/bootstrap`，三件套自动生成并实跑 gate 验证。

## 来源与致谢

- grilling、grill-me、grill-with-docs、domain-modeling、diagnosing-bugs、resolving-merge-conflicts、handoff、writing-great-skills 源自 [mattpocock/skills](https://github.com/mattpocock/skills)（MIT），部分经过修改（触发词收窄、悬空引用修复、可移植性调整）
- spine 融合了 [karpathy 编码守则]、ai-coding-agent-guidelines 的存活条款与 ponytail 极简主义阶梯的精华
- 工作流设计参考 Anthropic Claude Code 团队关于 loop engineering 的实践（gate、state file、maker/checker 分离、硬停止）

## License

MIT，见 [LICENSE](LICENSE)。
