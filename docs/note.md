# agent-skills 个人使用备忘

## 仓库架构

```
GitHub:
  vsiryxm/agent-skills          ← fork (origin, push 目标)
  addyosmani/agent-skills       ← 官方 (upstream, pull 源)

本地:
  ~/workspace/aiproject/agent-skills/

分支:
  main       → 纯同步官方更新，不提交自定义内容
  my-skills  → main + 自定义 skill，官方更新后 merge main
```

## 脚本说明

### setup.sh — 新机器初始化

在新机器上执行，完成 clone fork、配置 upstream、检出 my-skills 分支。

```bash
# 前提：SSH key 已配置好（能 ssh -T git@github.com）
cd ~/workspace/aiproject
# 把 setup.sh 拿过来（首次没有仓库，可从 fork 下载或手动 clone）
./setup.sh
```

脚本流程：
1. 检查 GitHub SSH 连通性，不通则中断
2. clone `vsiryxm/agent-skills` 到 `~/workspace/aiproject/agent-skills/`
3. 添加 upstream remote 指向 `addyosmani/agent-skills`
4. 检出 my-skills 分支（远程有则检出，无则创建）

### sync.sh — 日常同步官方更新

老机器上执行，拉取官方最新更新并同步到 fork。

```bash
cd ~/workspace/aiproject/agent-skills
./sync.sh
```

脚本流程：
1. `git checkout main && git fetch upstream && git merge upstream/main && git push origin main`
2. `git checkout my-skills && git merge main && git push origin my-skills`

## 自定义 skill

### dual-agent-pair-programming

位于 `skills/dual-agent-pair-programming/`，目录结构：

```
skills/dual-agent-pair-programming/
├── SKILL.md
└── references/
    ├── agent-a-playbook.md
    └── agent-b-playbook.md
```

修改后提交：

```bash
git checkout my-skills
# 编辑 SKILL.md 等...
git add -A && git commit -m "refactor: update dual-agent-pair-programming"
git push origin my-skills
```

## 零冲突原理

自定义内容放在两个官方不会触碰的位置：

- `skills/dual-agent-pair-programming/` — 全新目录，官方无同名
- `setup.sh`、`sync.sh`、`docs/note.md` — 根目录和 docs 下新文件

因此每次 `git merge main` 都是 clean merge，不会冲突。

## 修改日志

20260818: 
- 添加自定义skill: dual-agent-pair-programming

---

