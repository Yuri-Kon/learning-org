# Installing OCaml

内容来自于 [CS3110 Installing OCaml](https://cs3110.github.io/textbook/chapters/preface/install.html)
在这一节，我们将安装：

- 一个 Unix 开发环境
- OPAM：OCaml 包管理器
- 一个包含 OCaml 编译器及若干软件包的 OPAM *switch*
- 一个 Visual Studio Code 编辑器，支持 OCaml

## 使用 Nix 安装

项目目录位于 `org-learning/30-projects/cs3110-ocaml-nix/` ，我们将要在那里通过 Nix 配置 OCaml 环境

确认 flakes 可用：

``` shell
nix flake --help
nix develop --help
```

### Install OPAM: 在 Nix 路线中如何处理

CS3110 原文要求安装 OPAM, linux 用户需要参考 [opam 官网的发行版说明](https://opam.ocaml.org/doc/Install.html)
为了便于我们学习 Nix ，因此我们将采取 Nix-only 学习路线。即用 Nix 提供 `ocaml`、`utop`、`odoc`、`qcheck`、`biset_ppx`、`mehir`、`ocaml-lsp`、`ocamlformat` 等工具，这样可以在学习 OCaml 的同时理解 flake、devShell、依赖固定、项目级环境这些核心 Nix 概念。


## Initialize OPAM: 在 Nix-only 路线中跳过

CS3110 官方要求执行：

```shell
opam init --bare -a -y
```

并提醒不要在 `opam` 前加 `sudo`。

在 Nix-only 路线中，这一步可以跳过，因为该环境激活由：

```shell
nix develop
```

完成。 [Nix 官方手册说明](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-develop) ， `nix develop` 会启动一个 shell, 并提供接近 Nix 构建环境的交互式开发环境；默认会寻找 `devShells.<system>.default` 这样的 flake 输出。


## Create an OPAM Switch: 用 flake devShell 代替

CS3110 要求创建名为 `cs3110-2026sp` 的 switch ，并使用 `ocaml-base-complier.5.3.0` ，随后它要求安装这些包：

```shell
opam install -y utop odoc ounit2 qcheck biset_ppx menhir ocaml-lsp-server ocamlformat
```

同时要求确认 `utop` 启动时使用的是 OCaml 5.3.0

这里我们使用 Nix flakes 的写法。

首先输入：

```shell
nix flake init
```

这就会得到一个最小化的 `flake.nix` 文件，内容如：

```nix
{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
}
```

我们在其基础上修改：

```nix
{
  description = "CS3110 OCaml learning environment with Nix falkes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_3;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with ocamlPackages; [
          ocaml
          findlib
          dune_3
          utop
          odoc
          ounit2
          qcheck
          bisect_ppx
          menhir
          ocaml-lsp
          ocamlformat
        ];

        shellHook = ''
          echo "CS3110 OCaml environment"
          echo "OCaml: $(ocaml -version)"
          echo "Try utop"
        '';
      };
    };
}
```

然后执行：

```shell
nix develop
```
