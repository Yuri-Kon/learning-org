# 部分应用 partial application

partical application 可被翻译为“部分应用”或“部分实参应用”。它的意思是：一个函数原本需要多个参数，但我们先给它一部分参数，得到一个“等待剩余参数的新参数”。在OCaml中这非常自然，因为OCaml默认把多实参函数理解为“一层一层接收参数的函数”，也就是 [[lambda_expressions#多参函数与 lambda 演算|crried function]]。CS3110对此的解释是: `let add x y = x + y` 、`let add x = fun y -> x + y` 、`let add = fun x -> fun y -> x + y` 在语义上是等价的。

例如:

```ocaml
let add x y = x + y
```

它的类型会被推断为:

```ocaml
val add : int -> int -> int
```

这可以读成:

```ocaml
int -> (int -> int)
```

也就是说，`add` 先接收一个 `int` ，返回一个新的函数；这个新函数再接收一个 `int`，最后返回 `int` 。所以:

```ocaml
let add3 = add 3
```

这里 `add 3` 不会报错说参数不够，因为它 **合法地返回了一个函数** ：

```ocaml
val add3 : int -> int
```

然后:

```ocaml
add3 10
```

结果是 `13` 。

OCaml 官方文档也说明，curried function 是默认形式，因为它允许 partial application，而且写法上不需要额外的括号、逗号，也不需要对 tuple 做模式匹配。

## partial application 和 currying 的区别

要注意 partial application 和 currying 的区别。Currying 指的是把“接收多个参数的函数”转换成“一连串一次只接收一个参数的函数”。Partial application 指的是已经有这样一个函数之后，先给它一部分参数，得到另一个函数。这个过程是可以叉开的，比如说我们上面的例子:

```ocaml
let add x y = x + y
let add3 = add 3
```

`add` 这种多参数函数的形式体现 currying；`add 3` 这个动作体现 partial applicatin。CS3110也把 `t1 -> t2 -> t3` 解释为 curried function，并指出这种形式可以被部分应用。

## 右结合

右结合，就是当一个符号连续出现时，默认从右往左加括号。一般例子是:

```text
a ~ b ~ c
```

如果`~`是右结合，就解释为: `(a ~ b) ~ c`。
