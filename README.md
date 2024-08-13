#  TravellersBag

旅者行囊是一款转为现代macOS设计的，基于GPLv3.0协议开源的，旨在改善Mac用户的原神游戏外体验的工具集软件。
它通过官方的访问接口，提供了相对完整的功能，并且对于你的所有数据，本工具集都仅提供只读功能以充分保证使用时的数据安全。

TravellersBag is a tool set software designed for modern macOS, open source based on GPLv3.0 protocol, and designed to improve Mac users' Genshin Impact out of game experience.
It provides relatively complete functionality through the official interface, and for all your data, this toolkit only provides read-only functionality to fully ensure data security during use.

## 安装需求  /  Requirement
1. For both Intel(x64) and Apple Silicon(aarch64) Macs with macOS 13.0 and newer.
2. 你需要在开源许可协议的范围内使用，详细内容在初次安装后参见「初始化页面」的指引链接。
3. All of the interfaces we use are from miyoushe instead of HoYoLab, so you need to make sure your account is registed in China Mainland(Your server's name should be 「天空岛」or「世界树？」).

## 贡献 / Contribution
1. Feel free to open an issue when you find anything wrong with this app during use. (You'd better use Chinese Simplified)
2. Contract me by e-mail. (It is a shame that I have not enough knowledge about using Git.)

## 用到的技术栈 / Tech Stacks
1. [macOS SDK](https://developer.apple.com/documentation/)

## 从源码构建  / Build it yourself
确保你拥有 Xcode 15.0 及以上版本，或者你拥有 macOS SDK 14.0 及以上版本，这是我们在编写本程序时所依赖的开发环境。我们建议你前往 Apple Store 下载最新Xcode。
** 注意，你不应当使用 Swift6.0 作为 Swift 语言版本，否则本项目所依赖的SwiftlyJSON库将无法通过编译。 **

Make sure you have Xcode 15.0 or above, or macOS SDK 14.0 or above, which is the development environment we rely on when writing this program. We suggest that you go to the Apple Store to download the latest Xcode.
** Note that you should not use Swift6.0 as the Swift language version, otherwise the SwiftlyJSON library that this project relies on will not be able to compile. **

## 开发时的借鉴和参考
本应用的诞生离不开来自官方（米哈游天命科技有限公司）开发的高质量游戏《原神》，并通过其的OpenAPI访问数据；此外，开源社区的很多成熟的项目已经在这个方面做出了很好的实践，
在开发的过程中也参考和使用了它们的优秀成果，它们是：
1. UIGF.org - 祈愿和成就等数据的交换标准化组织
2. Snap.Hutao - 一款优秀的 Windows 端原神工具箱软件
3. GenshinPizzaHelper - 一款优秀的 Apple 平台的原神工具软件

# Have fun with Genshin Impact and TravellersBag!
