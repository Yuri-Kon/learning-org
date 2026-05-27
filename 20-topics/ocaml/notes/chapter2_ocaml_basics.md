---
title: OCaml 第二章：OCaml 基础
created: 2026-05-14
updated: 2026-05-16
course: CS3110
topics:
  - ocaml
  - basics
  - functional-programming
---

# The Basics of OCaml

这一章是真正开始学习 OCaml 的核心内容。其任务并不追求一下写复杂程序，而是建立一套语言学习的基本框架：看到一段 OCaml 代码时，能判断它的语法是什么、它如何求值、有什么类型、是不是符合 OCaml 的惯用写法。

[CS3110 第二章开头](https://cs3110.github.io/textbook/chapters/basics/intro.html) 先说 “如何学习一门编程语言”。教材把学习语言拆分成五个组成部分：syntax, semantics, idioms, libraries, tools, 也即是语法、语义、惯用法、库和工具。它特别强调，本课程在学习 OCaml 时，重点主要放在 semantics 和 idioms 上；语法当然要学，但语法不是最重要的部分。工具上，除了编译器和构建系统，最常用的是 toplevel,也即是可以交互式实验代码的环境。

接下来我们在搭建好 Nix 环境的前提下，转向“语义层”：一段 OCaml 程序到底怎么计算？它为什么有这个类型？它为什么以这个顺序求值？它和 Python/Java 的程序观有什么区别？

接下来我们的学习方式是：每学一个语法点，都问三个问题：它长什么样？它怎么求值？它有什么类型？

## toplevel

第一个核心概念是 toplevel 。可以理解为 OCaml 的 REPL 。CS3110 说它是类似于 Java 的 JShell 或 Python 的交互式解释器：它读取你的输入，求值，打印结果，然后等待下一次输入。它适合尝试小段代码，但是不要过度依赖。因为大程序仍然需要编译、构建和测试工具。

在我们的项目里，标准的启动方式应该是：

```shell
nix develop
utop
```

这里的 `nix develop` 是我们给 OCaml 学习所提供的可复现开发环境入口。进入 `utop` 后，输入：

```ocaml
42;;
```

会得到：

```ocaml
- : int = 42
```

这行输出是 OCaml 初学最重要的格式之一。它从右往左读：`42` 是值，`int` 是类型，`-` 是表示这个值没有绑定名字。这个例子说明，toplevel 会对表达式求值，并告诉我们结果的值和类型。

这就引出第二个概念：expression, 也就是表达式。

## expression

OCaml 语法中最主要的构成单位是表达式；命令式语言的程序主要由 commands 构成，函数式语言的程序主要由 expressions 构成。表达式的核心任务是被求值为 value。value 是一种 **“已经没有剩余计算要做的表达式”** 。所以所有 **值** 都是表达式。但不是所有表达式都是值。比如 `2`, `true`, `yay!` 是值；`1 + 2` 是表达式，但它还需要计算，计算结果才是值 `3`。

这个区别非常关键。之前熟悉的 Python 和 Java 往往让我们把程序理解成 “一步步执行命令”，而 OCaml 会训练我们把程序理解成 “表达式如何求值”：

```ocaml
let x = 1 in
x + 1
```

这里改变的是对于程序的基本想象。命令式程序更像 “改变世界的一系列动作”；函数式程序更像 “构建一个表达式，并根据规则求出它的值”。

但是表达式求值也可能失败。CS3110 提到两种情况：一种是求值过程中抛出异常，另一种是求值永不终止，比如进入无限循环。所以 “表达式会被求值为值” 是正常路径，但语言必须处理异常和不终止。

## 基本类型

OCaml 的 primitive types 包括整数、浮点数、字符、字符串和布尔值。这些内建基础类型和其他语言中的基础类型很相似，但 OCaml 在运算符、类型转换和相等性上有一些很有函数风格的设计。

### `int`

整数 `int` 很直观：

```ocaml
1;;
1 + 2;;
65 / 60;;
65 mod 60;;
```

`/` 是整数除法，`mod` 是取模。比如 `65 / 60` 的运算结果是 `1` ，因为这里是整数除法。

如果写：

```ocaml
65 / 0;;
```

会出现异常。这是 “表达式求值失败” 的一个例子。表达式在语法上合法，类型上也合法，但在运行时无法得到正常值。

CS3110 特别指出，在现代平台上 OCaml 的 `int` 范围通常是 `-2^62` 到 `2^62 - 1` 。原因是 OCaml 是用 64 位机器字表示整数，但运行时会“偷走”一位，用来区分整数和指针。因此它不是完整的64位有符号整数。如果真的需要64位整数，可以使用标准库的 `Int64`；如果需要任意精度整数，可以使用 `Zarith` 。

这一点对我们理解 OCaml 很有价值：OCaml 是高级函数式语言，但它不是脱离机器的数学语言。 `int` 不是数学整数，仍然受到运行时表示和机器字长限制。

### `float`

浮点数 `float` 的写法必须带点：

```ocaml
3.;;
3.0;;
3.14;;
```

`3.` 是float , `3` 是 int。OCaml 可以不支持算术运算符重载，所以整数和浮点数使用不同的运算符：

```ocaml
1 + 2;;
3.14 *. 2.;;
```

整数加法是 `+` ，浮点数加法是 `+.` ；整数乘法是 `*` ，浮点数乘法是 `*.` 。 那么，如果写：

```ocaml
3.14 * 2.;;
```

会报错。因为 `*` 运算符期待整数。

> [!WARNING]
> OCaml 不会在 `int` 和 `float` 之间自动转换；需要转换时，我们需要显式使用 `float_of_int` 或 `int_of_float`。

比如：

```ocaml
3.14 *. float_of_int 2;;
```

这个设计和 Python、Java 里不太一样。Python 中这样的表达式可以直接算，Java 里也会通过数值提升处理。OCaml 在这里更严格。它希望我们能明确表达“这是整数计算” 还是 “这是浮点计算”，这会让初学者多写几个符号，但长期看能减少隐式转换造成的误解。

浮点数还有个所有语言共有的问题：近似表示。

> [!TIP]
> CS3110 用 `0.1 +. 0.2` 提醒读者，浮点数遵循近似表示，可能出现舍入误差。Python 和 Java 也一样。

### `bool`

布尔值是：

```ocaml
true;;
false;;
```

常用逻辑运算是：

```ocaml
true && false;;
true || false;;
not true;;
```

> [!IMPORTANT]
> 这里，`&&` 和 `||` 是短路运算。也就是说， `false && e` 不会继续求值 `e` ， `true || e` 也不会继续求值 `e` 。这和 Java , Python 中的短路逻辑类似。

#### 关于逻辑运算符

可以这样理解， OCaml 中 `||` 和 `&&` 是 `bool` 类型专用的短路逻辑运算符，它们的左右操作都必须是 `bool` ，其结果也一定是 `bool` 。

我们可以把 `||` 看成一个普通函数，只是写法特殊：

```ocaml
(||) true false
```

它等价于：

```ocaml
true || false
```
而由于它的类型是：

```ocaml
bool -> bool -> bool
```

因此，它一定要求第一个参数是 `bool`, 第二个参数也是 `bool` 。

比如：

```ocaml
3 > 1 && 4 < 5
n = 0 || odd (n - 1)
```

这些都可以，因为左右两边的值都是 `bool`

但是下面这些在 Java 、 Python 中常见的不可以：

```ocaml
1 || 2
"hello" && "world"
[] || [1; 2; 3]
```

OCaml 不会像 C、Python、JavaScript 那样把 `0` 、空字符串、空列表自动当作真假值。它要求我们显式写出布尔条件。

比如不能写：`if xs then...` ，如果 `xs` 是列表，则应该写：

```ocaml
if xs <> [] then ...
```
或者更常见地使用模式匹配：

```ocaml
match xs with
| [] -> ...
| _ :: _ -> ...
```

### `char` 和 `string`

字符 `char` 用单引号：

```ocaml
'a';;
'b';;
```

字符串 `string` 用双引号：

```ocaml
"abc";;
```

字符串拼接用 `^`:

```ocaml
"abc" ^ "def";;
```

这和 Java/Python 有明显区别。Java 和 Python 通常用 `+` 拼接字符串，OCaml 使用独立的 `^` 。这是 OCaml “不随意重载运算符” 的又一个表现。

字符串和数字之间的转换要显式写。

```ocaml
string_of_int 42;;
int_of_string "123";;
```

这里，如果我们写：

```ocaml
int_of_string "not a int";;
```

会抛出异常。这里再次出现 “静态类型检查无法解决所有问题” 的边界：编译器知道 `"not an int"` 是字符串，也知道 `int_of_string` 接收字符串；但它无法在一般情况下保证这个字符串内容一定能被解析为整数，所以失败会发生在运行时。

字符串取字符使用：

```ocaml
"abc".[0];;
"abc".[1];;
```

索引从 0 开始。如果越界访问，会抛异常：

```ocaml
Exception: Invalid_argument "index out of bounds".
```

## 相等运算

OCaml 有两组相等和不等：

```ocaml
=
<>
==
!=
```

> [!IMPORTANT]
> CS3110 强烈提醒：现在开始训练自己使用 `=` ，不要使用 `==`。`=` 和 `<>` 检查结构相等，`==` 和 `!=` 检查物理相等。物理相等要等到学习可变性和运行时表示时才能讲清楚。对于来自 java 的学习者，这一点尤为重要。因为 Java 使用 `==` 比较基本值，而对象相等又涉及 `equals` 。OCaml 初学阶段先形成习惯：一般比较值是否相等，使用 `=`。

比如下列表达式：

```ocaml
1 = 1;;
"abc" = "abc";;
1 <> 2;;
```

这里先不要写 `"abc" == "abc"` ，即便有时候这个能得到想要的结果，也不应该用它来表示值普通相等。

## `assert`

`asset e` 会直接求值表达式 `e` 。如果结果是 `true` ，整个`assert` 产生 `unit` 值 `()` ；如果结果是 `false` ，抛出异常。 CS3110 建议用一系列 `assert` 来测试函数，例如 `let () = assert (f input1 = output1)`

比如：

```ocaml
let square x = x * x;;
let () = assert (square 3 = 9)
let () = assert (square 0 = 0)
let () = assert (square -2 = 4)
```

这里的 `let () = ...` ，是因为 `assert (..)` 成功是返回 `()` ，也就是 `unit` 值；`let () =` 表示 “我知道右边应该是 unit ，并且我不需要给它命名”。这在 OCaml 中很常见，尤其是测试、打印、初始化这类有副作用的代码。

## `if`

`if` 是第二章最重要的语义训练之一。

OCaml 的 `if` 是表达式：

```ocaml
if 3 + 5 > 2 then "yay!" else "boo!";;
```

这里，它不是 Java/Python 中那种主要用于控制流程的 statement。CS3110 明确指出，OCaml 的 `if-then-else` 和其他 **表达式** 一样，可以放在任何需要表达式的位置；它类似其他语言中的三元表达式。

例如：

```ocaml
4 + (if 'a' = 'b' then 1 else 2);;
```

这里的 `if 'a' = 'b' then 1 else 2` 就是一个表达式。它在这里的值是2，所以整个表达式的值是 `6`。

### `if` 的语义

`if` 的动态语义是：先求值 guard ，也就是 `if` 后面的条件。如果 guard 是 `true` ，求值 `then` 分支。如果 guard 是 `false` ，求值 `else` 分支。没有被选中的分支不会求值。 CS3110 把这种描述为 evaluation rules。

`if` 的静态语义是：guard 必须是 `bool`；`then` 分支和 `else` 分支必须有同一个类型 `t`；整个 `if` 表达式的类型就是这里的 `t` 。CS3110 把这种描述为 typing rules。

所以这个合法：

```ocaml
if true then 1 else 2;;
```

而这个不合法： 

```ocaml
if true then 1 else "no";;
```

因为 `then` 分支是 `int` ，`else` 分支是 `string` 。编译器不会说 “反正 guard 是 `true` ，所以 `else` 不会用到”。类型检查发生在编译期，它不按照运行时路径做这种特殊推理。教材也提醒，编译期类型检查时通常不知道 guard 运行时会是什么值。

这就是静态语义和动态语义的区别。动态语义回答“运行时怎么求值”；静态语义回答 “编译期怎么判断这个程序是否合法”。 CS3110 第二章开头已经说，语义分为 dynamic semantics 和 static semantics ，类型检查是静态语义中最重要的一种。

## `let`

这部分非常重要。 `let` 是 OCaml 程序组织的基础。

### `let definition` 和 `let expression`

比如：

```ocaml
let x = 42;;
```

这是一个 `let definition` ，也就是定义。它在 toplevel 或 `.ml` 文件中把名字 `x` 绑定到值 `42` 。CS3110 特别区分了 definition 和 expression：`let x = 42` 这种 **顶层定义本身不是表达式** ，它不会像 `1 + 2` 那样被放到任意表达式的位置。

另一种是 `let expression`:

```ocaml
let x = 42 in x + 1;;
```

这里 `x` 只在 `in` 后面的 `body expression` 中有效。 整个 `let x = 42 in x + 1` 是表达式，它会求值为 `43`。

一个很直观的例子就是，对于 `let x = 42` 这样的 `let definition` ，我们可以在接下来直接访问它：

```ocaml
x;;
```

输出为：

```ocaml
- : int = 42
```

而如果对于 `let y = 42 in y + 1` 这样的 `let expression` ，我们无法在后文访问这个 `y`:

```ocaml
Error: Unbound value y
```

这就是区别。CS3110 给出的动态语义是：先把 `e1` 求值为 `v1` ，然后在 `e1` 中用 `v1` 替换掉 `x` ，得到新表达式，再求新表达式。

比如：

```ocaml
let x = 1 + 4 in x * 3
```

求值过程可以理解为：

```
let x = 1 + 4 in x * 3
=> let x = 5 in x * 3
=> 5 * 3
=> 15
```

这里是替换模型。是 CS3110 后续理解函数调用、作用域和解释器的核心。现在我们不必把它形式化，但要形成直觉： `let` 是把一个表达式的值绑定给名字，然后在 body 中使用这个名字。

### `let` 的语义

`let` 的静态语义是：如果 `e1: t1` ，并且在假设 `x: t1` 的情况下 `e2: t2` ，那么整个 `let x = e1 in e2` 的类型就是 `t2`

比如：

```ocaml
let x = 1 + 2 in x * 3
```

`1 + 4 : int` ，所以 `x : int` 。在这个假设下，`x * 3 : int` ，因此整个表达式的类型是 `int` 。

这里可以和 Nix 做一个很有意思的对照。Nix 官方文档把 “Names and values” 和 “functions” 作为语言基础内容。Nix 中的：

```nix
let
  x = 42;
int
  x + 1
```

和 OCaml 中的:

```ocaml
lex x = 42 in x + 1
```

都体现了函数式语言的 “名字绑定 + 表达式求值” 的思维。区别在于： OCaml 是静态类型语言， Nix 是动态类型语言；OCaml 的类型错误很多在编译期时发现， Nix 的表达式错误通常在求值时暴露。

## 函数

> [!NOTE]
> Methods and functions are not same idea.

方法和函数不是同一类概念。方法是对象的组成部分，通常有隐式接收者，比如 Java 的 `this` 或 Python 的 `self` ；OCaml 这里讲的是函数，它们不是对象的组成部分，也没有隐式接收者。对于有面向对象背景的人，要小心这个术语差异。

在 Java 中我们经常写：

```Java
account.deposit(100);
```

这里 `deposit` 是方法（method），它隐含 `account` 这个 receiver 。

在 OCaml 我们写：

```ocaml
let deposit balance amount = balance + amount
```

这里 `deposit` 是函数，它显式接接收 `balance` 和 `amount` ，返回新的值。没有隐藏的 `this` ，也不会默认修改某个对象内部状态。

### 递归与非递归函数

非递归函数定义：

```ocaml
let f x = ...
```

递归函数定义：

```ocaml
let rec f x = ...
```

> [!NOTE]
> 这里有些意外的是， OCaml 需要显式写出 `rec` 才能定义递归函数。而许多语言都可以默认调用自身。

经典来自就是阶乘：

```ocaml
(** [fact n] is [n!].
    Requires: [n >= 0]. *)
let rec fact n = 
  if n = 0 then 1 else n * fact(n - 1)
```

这里文档注释中的 `Requires` 是前置条件：调用者需要保证 `n >= 0` 。 `[fact n] is [n!]` 是描述的后置条件，也就是函数结果的意义。这里，通过 `rec` 来定义递归函数。

再比如幂函数：

```
(** [pow x y] is [x] to the power of [y].
    Requires: [y >= 0]. *)
let rec pow x y =
  if y = 0 then 1 else x * pow x (y - 1)
```

这里没有写任何类型，但是 OCaml 能推断出：

```ocaml
val pow : int -> int -> int = <fun>
```

这可以展示类型推导。因为 `y = 0` ，所以 `y` 是 `int` 。又因为 `if` 分支里有 `1` ，所以整个 `if` 返回 `int`（[[chapter2_ocaml_basics#`if` 的语义|可以参考这里]]）。因为使用 `*` ，所以参与运算的 输入的 `x` 也必须是 `int` ；所以函数类型是 `int` 。

> [!summary] 与 Java 等的不同
> 这就是 OCaml 类型推导的基本体验。我们不必像 Java 那样处处写类型，但它也不是动态类型。类型依旧存在，而且编译器会主动推导并检查。

当然我们也可以手动写类型标注：

```ocaml
let rec pow (x : int) (y : int) : int = if y = 0 then 1 else x * pow x (y - 1)
```

CS3110 通常建议省略这些标注，因为让编译器推断更简洁；但在遇到不理解的类型错误时，显式标注可以帮助调试。

### 函数定义的语义

函数定义的语义可以用一句话理解：如果在假设参数 `x1 : t1`, `x2 : t2` ...... 的情况下，函数体 `e` 有类型 `u` ，那么函数 `f` 的类型就是： `t1 -> t2 -> ... -> u` 。递归函数多数有了一个假设：在检查函数体时，函数名 `f` 自己也在作用域内，所以可以在函数体中调用自己。

这里需要引入一点后面的知识：

函数体的类型 `u` 通常不是 “唯一的 **具体类型** ”，而是唯一的 **最一般类型**，也就是 principal type 。

例如：

```ocaml
let id x = x
```

函数体 `x` 的类型并没有被固定为某一个具体类型：`int` , `float` , `bool` 等。 OCaml 会给出这样的推断：

```ocaml
val id : 'a -> 'a = <fun>
```

这里的 `'a` （单引号）是类型变量，表示 “对任何类型都成立”。所以它在编译期并不会固定到某一个具体的类型，而是一个多态类型。

在递归中，还会有一种无限递归的情况：

```ocaml
let rec loop x = loop x
```

OCaml 会给它类型：

```ocaml
val id : 'a -> 'b = <fun>
```

这意味着：类型系统只保证 “如果这个表达式产生了值，那么这个值符合类型约束”。因此运行时会无限递归。它不保证一定会终止。

### 互递归函数 mutually recursive functions

使用 `and` 来使用互递归函数：

```ocaml
let rec even n = 
  n = 0 || odd (n - 1)
and odd n =
  n <> 0 && even (n -1)
```

OCaml 类型推断为：

```ocaml
val even : int -> bool = <fun>
val odd : int -> bool = <fun>
```

这里 `even` 和 `odd` 相互调用，所以必须放在同一个 `let rec  ... and ...` 的结构里。

### 匿名函数

OCaml 中函数可以没有名字：

```ocaml
fun x -> x + 1
```

返回如：

```ocaml
- : int -> int = <fun>
```

其中的 `-` 就表示 [[chapter1_better_programming_through_ocaml#小练习|没有名字]] 。这个函数的意思是：“接收 `x` ，返回 `x + 1` 的函数。

> [!TIP]
> CS3110 说匿名函数也叫 `lambda expressions`，这个术语来自 `labmda calculus` ，也就是一种和图灵机一样重要的计算模型

下面这两种写法语义等价:

```ocaml
let inc x = x + 1
let inc = fun x -> x + 1
```

第一种更像普通函数定义，第二种更明确地表示: `inc` 是一个名字，它绑定到一个函数的值。这个角度非常重要，因为 OCaml 中函数就是值。 OCaml 官方文档也明确说，函数可以作为值使用，可以传给函数，也可以从函数返回。

这会慢慢引出高阶函数。比如以后我们会写:

```ocaml
List.map (fun x -> x + 1) [1; 2; 3]
```

这里 `(fun x -> x + 1)` 没必要单独命名，因为它只在这一行作为参数传给 `List.map`

### 函数调用

函数调用，也就是 function application ，是 OCaml 的核心语义。

OCaml 函数调用时不需要括号:

```ocaml
square 5
add 2 3
pow 2 10
```

这和 Java / Python 很不同:

```Java
square(5)
add(2, 3)
```

OCaml 的语法更接近数学和 ML 系语言传统：函数名后跟参数，中间用空格。简化为:

```ocaml
e0 e1 e2 ... en
```

其中 `e0` 是函数， `e1` 到 `en` 是参数。静态语义是: 如果 `e0 : t1 -> ... -> tn -> u` ，并且每个参数类型匹配，那么整个函数应用的类型是 `u` 。动态语义是：先把函数表达式和参数表达式求值，再把参数值替换进函数体，最后求值函数体。

函数应用和 `let` 表达式都涉及 substitution 。甚至:

```ocaml
let x = e1 in e2
```

可以看成:

```ocaml
(fun x -> e2) e1
```

它们语法不同，但语义等价。[[lambda_expressions#lambda 与 `let` 的关系|参见这里]] 。

这个观察非常重要。它告诉我们， `let` 不只是 “变量赋值语法”，它可以被理解为匿名函数应用的语法糖。这样我们就可以慢慢理解为什么 OCaml 的语法核心很小，但是表达能力很强。

## pipeline operator

接下来是 pipeline operator , 也就是 `|>`

假设:

```ocaml
let inc x = x + 1
let square x = x * x
```

普通写法:

```ocaml
square (inc 5)
```

pipeline 写法:

```ocaml
5 |> inc |> square
```

这里的意思是： `|>` 的隐喻是把值从左到右送入管道。 `e1 |> e2` 等价于 `e2 e1` 。它的好处是当函数调用链变长时，阅读顺序更自然。

比如:

```ocaml
5 |> inc |> square |> inc |> inc |> square
```

比下面这种括号嵌套更容易顺着读:

```ocaml
square (inc (inc (square (inc 5))))
```

这个写法和 [Unix shell 管道](https://en.wikipedia.org/wiki/Pipeline_(Unix))、 [Elixir 管道](https://elixirschool.com/en/lessons/basics/pipe_operator)、 [`F#` 管道](https://theburningmonk.com/2011/09/fsharp-pipe-forward-and-pipe-backward/) 都有类似直觉。这可以和 Nix 中 “表达式逐层组合” 的习惯联系起来：函数式代码经常不是 “中间变量到处改”，而是 “一个值经过一系列函数变化” 。

## 多态函数

最简单的多态函数是 indentity function:

```ocaml
let id x = x
```

这里 OCaml 会推断类型:

```ocaml
val id: 'a -> 'a = <func>
```

`'a` 是类型变量，表示未知类型。[[chapter2_ocaml_basics#函数定义的语义|可以参考]] 。CS3110 解释说，类型变量总以单引号开头，常见有 `'a`、`'b`、`'c` 。因为 `id` 可以作用于很多类型，所以它是多态函数（polymorphic function）。

例如:

```ocaml
id 42;;
id true;;
id "bigred";;
```

都可以实现。这和 Java 的范性可能有一点类似，但是体验不同。在Java里可能写：

```java
<T> T id(T x) {
  return x;
}
```

OCaml 通常不需要显示写范型函数。它通过类型推导发现这个函数对任何类型都成立。

不过也可以把多态函数限制成更具体的类型:

```ocaml
let id_int (x: int) : int = x
```

此时如果 `id_int true` 就会报错。

> [!tip] 承诺
> CS3110 还给出了一个重要的行为视角: `'a -> 'a` 比 `int -> int` 承诺得更多。`id` 保证对任意输入都返回同类型输出；如果只需要一个 `int -> int` ，可以使用 `id` ，因为它当然也满足这个承诺。反过来，如果需要 `'a -> 'a` ，则不能用只支持整数的 `int -> int` 代替。

这对理解类型系统很有帮助。类型不只是一个标签，它是一种“行为承诺”。类型越多态，表示这个函数越通用，也表示它**能做的事情反而越受限制**。因为比如 `'a -> 'a` 不能对 `x` 做加法。因为它不知道 `x` 是不是整数。多态给了函数更广泛的适用范围，同时也限制了函数体依赖的操作。

## 部分应用 partial application

我们举一个例子。定义:

```ocaml
let add x y = x + y
```

它的类型是:

```ocaml
int -> int -> int
```

我们之前把它理解为是“接受两个int，返回一个int”。但是CS3110进一步指出，[[lambda_expressions#多参函数与 lambda 演算|函数类型是右结合的]]:

```ocaml
int -> (int -> int)
```

也就是说，`add` 接受一个整数，返回一个新的函数（`int -> int`）；这个新函数再接受一个整数，最终返回结果。

所以可以写：

```ocaml
let add5 = add 5
```

那么我们如果执行:

```ocaml
let add5 2
```

得到的结果是 `7`。

**以上过程就是部分应用(partial application)** 。函数没有一次性拿到全部参数，也可以先拿到一部分参数，返回一个等待剩余参数的新函数。我们还可以进一步观看这个函数:

```ocaml
let addx x = fun y -> x + y
```

`addx` 和 `add` 从类型角度出发都是 `int -> int -> int` 。
