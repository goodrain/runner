# Runner
用来运行  [builder](https://github.com/goodrain/builder) 制作的tgz文件，每一个源码构建的应用都是由runner镜像加载运行的。

## Runner 运行原理

通过标准输入，文件挂载或者URL的形式将 压缩后 的应用程序（代码，运行时）传入到Runner镜像并运行。镜像的入口文件会读取Procfile中的内容并运行。

## 如何使用 Runner
云帮安装后该镜像自动在计算节点拉取，不需要人工干预。下面主要介绍手动通过runner镜像运行builder生成的压缩包的场景。


可以通过标准输入将压缩包载入到runner镜像，并运行：

```bash
$ cat myslug.tgz | docker run -i -a stdin -a stdout goodrain.me/runner
```

压缩包的内容会在runner容器启动后解压到 `/app` 目录，在正式启动应用程序之前，会先导入代码目录下 `.profile.d` 中的文件，这里会有应用程序所需要的环境变量。

最终，runner镜像的引导程序会读取代码目录下的`Procfile`文件，并启动应用程序。如果用户代码根目录中没有该文件，在builer构建时会根据用户在创建应用向导中的选择自动生成。
