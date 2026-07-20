# agent-playbook

强模型时代的个人 AI coding-agent playbook：一条从需求拷问到交付验收的完整链路，跨 Claude Code 与 Codex CLI。以 skill 为主体，未来也会收纳独立的 plugins/hooks 等 agent 增强件。

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
├─ 大任务？          → /spec-to-delivery：spec 冻结 → 计划 → 实现(小步 checkpoint commit)
│                      → gate 脚本 → 独立审查(≤2轮) → 交付报告
├─ 卡硬 bug？        → (自动) diagnosing-bugs：先造红灯命令，再谈假设
├─ 验收 agent 产出？ → /review-worker：gate 先跑 → 判断性审查 → 人工验证表
├─ 会话要断/换端？   → /handoff
└─ git 冲突？        → (自动) resolving-merge-conflicts
```

一句话记忆：**groundwork 无处不在，grill 在动手前，spec-to-delivery 在做大事，diagnose 在卡死时，review 在收货时，handoff 在离场时。**

## Skill 清单

| Skill | 角色 |
| --- | --- |
| groundwork | 行为基线：假设显式化、最小手术式改动、根因修复、验证纪律、fail loud、路由表 |
| spec-to-delivery | 复杂交付：task packet(spec/task/review)、可执行验收标准、gate、独立审查、循环化出口 |
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
Skills (12)  bootstrap, diagnosing-bugs, domain-modeling, grill-me, grill-with-docs,
             grilling, groundwork, handoff, resolving-merge-conflicts, review-worker,
             spec-to-delivery, writing-great-skills
Agents (1)   reviewer
Hooks (0)
Always-on:   ~1,128 tok   added to every session
```

## 安装

### Claude Code（推荐：官方插件机制）

本仓库是一个标准 Claude Code 插件（`.claude-plugin/marketplace.json` + `plugin.json`），skills 和 agents 按目录约定自动发现，无需任何同步脚本。

```
/plugin marketplace add Wsr-7/agent-playbook
/plugin install agent-playbook@agent-playbook
```

私有仓库需要先给协作者开 GitHub 访问权限。本地开发/未推送时可直接从磁盘临时加载验证：

```powershell
claude --plugin-dir "path/to/agent-playbook" plugin details agent-playbook   # 查看清单与 token 成本
claude --plugin-dir "path/to/agent-playbook"                                  # 会话内启用一次性试用
```

### Codex CLI

`.codex-plugin/plugin.json` 声明了同一份清单，但 Codex 目前没有已验证的自动安装命令——手动同步：

```powershell
git clone https://github.com/Wsr-7/agent-playbook
Copy-Item agent-playbook\skills\* ~\.codex\skills\ -Recurse -Force
```

### 其他平台

克隆仓库后把 `skills/` 下的目录按平台约定复制到对应的 skills 目录即可——每个 SKILL.md 都是自包含的纯 Markdown，不依赖仓库其他文件。

## 项目侧配套（templates/）

skill 是通用约定，每个项目还需落地件（复制模板后按项目改）：

- `templates/gate.ps1` → 项目的 `scripts/gate.ps1`：确定性验收门（测试/构建/git 状态），review-worker 和 spec-to-delivery 会自动找到并优先执行它
- `templates/STATE.md` → 项目根或本地文档目录：循环状态文件，记录进行中/已完成/待人工验证/lessons
- `templates/hooks/inject-state.ps1` → `~/.claude/hooks/`：SessionStart hook，会话启动时强制注入项目 STATE.md（安装方式见文件头注释）——强制注入优于指望模型自觉去读。这个 hook **不**随插件自动安装：它会在每个项目的每次会话触发，属于用户级决定，需手动装

Hook 是可选增强，不是依赖：平台不支持 hooks 时，groundwork 的开工规则会以 prose 方式兜底（开工先读 STATE.md 和 lessons）——概率性但通常有效；支持 hooks 的平台装上后升级为确定性注入。所有 skill 在无 hook 环境下功能完整。reviewer agent 同理：无自定义 agent 能力的平台退回 spec-to-delivery §7 的 prose 版 reviewer brief。

新项目接入最快路径：装好插件后在项目里说 `/bootstrap`，三件套自动生成并实跑 gate 验证。

## 进化触发器（记录在案，触发前不做）

- 项目 CLAUDE.md 超过约 200 行、或不同模块的约定开始互相冲突 → 参考 Trellis 的 spec 树：按模块拆分域规范，按需注入
- 并行任务多到 STATE.md 手工维护吃力 → 再评估任务状态机（这是引入运行时脚本依赖的唯一正当理由）
- 除 skill 外开始积累独立的 plugin/hook 资产 → 仓库已预留这个定位（见开头一句话），届时按需建目录，不提前占位

## 来源与致谢

- grilling、grill-me、grill-with-docs、domain-modeling、diagnosing-bugs、resolving-merge-conflicts、handoff、writing-great-skills 源自 [mattpocock/skills](https://github.com/mattpocock/skills)（MIT），部分经过修改（触发词收窄、悬空引用修复、可移植性调整）
- groundwork 融合了 karpathy 编码守则、ai-coding-agent-guidelines 的存活条款与 [ponytail](https://github.com/DietrichGebert/ponytail) 极简主义阶梯的精华；插件清单结构（marketplace.json/plugin.json 双清单）也参考了 ponytail 的真实实现
- 工作流设计参考 Anthropic Claude Code 团队关于 loop engineering 的实践（gate、state file、maker/checker 分离、硬停止），部分理念借鉴自 [Trellis](https://github.com/mindfold-ai/Trellis)（状态注入 hook、冷启动、spec 晋升闭环）

## License

MIT，见 [LICENSE](LICENSE)。
