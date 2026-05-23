# 实验回顾

源代码位于: `~/Projects/school/compiler-principle/experiment/expr3/`

## 为什么要有中间代码？

编译器通常分为三个大阶段:

```text
源代码 -> [前端: 词法+语法+语义] -> 中间代码 -> [后端: 优化+目标代码生成]
```

中间代码（IR）是一种平台无关的、比汇编更高级、比源码更低级的表示形式。引入它的好处是：前端和后端解耦——换一个CPU架构，只需要重写后端，不必重写前端。

---

## 三地址码长什么样？

三地址码的意思是：每条指令最多有三个操作数，形如:

```text
result := x + y       ← 二元运算
result := #0 - x      ← 一元运算（取负）
result := *addr       ← 从地址读值
*addr := value        ← 向地址写值
IF x > y GOTO label1  ← 条件跳转
GOTO label1           ← 无条件跳转
LABEL label1 :        ← 标号
FUNCTION fact :       ← 函数入口
PARAM n               ← 声明形参
ARG x                 ← 传实参（反序）
result := CALL fact   ← 函数调用
RETURN result         ← 返回
READ x                ← 内置读入
WRITE x               ← 内置输出
DEC arr 40            ← 数组/结构体申请空间
```

以 `test_1.cmm` 为例，翻译结果大致是：

```c
int main()
{
  int  n;
  n = read();
  if (n > 0) write (1);
  else if (n < 0) write (-1);
  else write(0);
  return 0;
}
```

```text
FUNCTION main :
READ t1
n := t1
IF n > #0 GOTO label1
GOTO label2
LABEL label1 :
WRITE #1
t2 := #0
GOTO label3
LABEL label2 :
IF n < #0 GOTO label4
GOTO label5
LABEL label4 :
t3 := #0 - #1
WRITE t3
t4 := #0
GOTO label6
LABEL label5 :
WRITE #0
t5 := #0
LABEL label6 :
LABEL label3 :
RETURN #0
```

---

## IR 的存储与输出 —— `ir.c`

```c
typedef struct IrLine {
  char *text;
  struct IrLine *next;
} IrLine;

static IrLine *head = NULL;
static IrLine *tail = NULL;
```

`ir.c` 维护一个单链表，每条三地址码就是链表中的一个节点（一行文本）。整个翻译期间只追加（`ir_emit`），翻译完成后统一写入文件（`ir_print`）。

```c
void ir_emit(const char *fmt, ...) {
  char buf[512];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap); 

  IrLine *line = (IrLine *)xmalloc(sizeof(IrLine));
  line->text = xstrdup(buf);
  if (!head) {
      head = line;
  } else {
      tail->next = line;
  }
  tail = line;
}
```

`ir_emit` 接受 `printf` 风格的格式串，所以调用者只需写例如 `ir_emit("%s := %s + %s", place, left, right)`，非常直观。

---

## 临时变量与标号

三地址码中的变量有两类：

- 源码中的变量：直接用原名，例如 `n` ， `result`
- 临时变量：翻译复杂表达式时由编译器创建，叫 `t1`，`t2` ...

```c
static void new_temp(char *buf, size_t size) {
    snprintf(buf, size, "t%d", temp_no++);
}
static void new_label(char *buf, size_t size) {
    snprintf(buf, size, "label%d", label_no++);
}
```

全局计数器 `temp_no` 和 `label_no` 单调递增，保证每个临时名唯一。

---

## 表达式翻译 —— `translate_exp`

这是核心函数
