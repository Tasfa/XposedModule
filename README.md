# XposedModule

## Usage: 

1. 将整个文件夹copy到`{Android Studio installation dir}/plugins/android/lib/templates/other/`
2. 在Java文件夹右键->New->Other->XposedModule
3. 填写相关信息即可

## 懒人福利: 一秒创建Xposed模版

> ###懒惰是科技的第一生产力

### 0x00 背景
* 由于Android逆向每次想要使用Xposed进行Hook时，总是需要重复性地操作一遍Android Studio新建项目的流程.ps:当然可以只用一个项目，强迫症需要分开 ：）
* 由于Xposed实现的方式，每次修改hook代码后，需要重启机器，这也是白白浪费了很多时间。
* 基于以上两点，参考现有的方案，**实现了一个Module,只需在AS中new一下即可解决问题**。

### 0x01 创建XposedModule
**1.效果:**
![效果图](http://www.tasfa.cn/wordpress/wp-content/uploads/2018/04/2222.png)

**2.代码结构:**

![目录树](http://www.tasfa.cn/wordpress/wp-content/uploads/2018/04/目录树.png)

**3.代码解析:**

template.xml:

``` xml
<?xml version="1.0"?>
<template
    name="XposedModuleFreeRestart"
    description="Creates a new Xposed Module without restart"
    format="3"
    minApi="15"
    minBuildApi="15"
    revision="4">

    <category value="Other"/>

	<!-- parameter 主要是:效果图中，需要输入的几个设置栏 -->
    <parameter
        name="Xposed Mod class"
        constraints="nonempty|unique|class"
        default="XposedMod"
        help="Class that contains Xposed code"
        id="xposedModClass"
        type="string"/>

    <parameter
        name="Xposed Description"
        constraints="nonempty"
        help="Description of Xposed Module"
        id="xposedDescription"
        type="string"/>

    <parameter
        name="Package name"
        constraints="package"
        default="com.xxx.xxxx.xposed"
        id="packageName"
        type="string"/>

    <parameter
        name="Hooked Package name"
        constraints="nonempty"
        default="com.xxxx.xxx.xposed"
        id="hookPackageName"
        type="string"/>

	<!-- Module图标 -->
    <thumbs>
        <thumb>template_xposed_module.png</thumb>
    </thumbs>

	<!-- 全局变量 -->
    <globals file="globals.xml.ftl"/>
    
    <!-- 需要执行的操作 关键点-->
    <execute file="recipe.xml.ftl"/>

</template>

```

recipe.xml.ftl

``` xml
<?xml version="1.0"?>
<recipe>

    <!-- 创建文件 -->
    <mkdir at="${escapeXmlAttribute(manifestOut)}/assets/"/>

    <!-- 移动合并文件 -->
    <merge from="AndroidManifest.xml.ftl" to="${escapeXmlAttribute(manifestOut)}/AndroidManifest.xml"/>

    <merge from="build.gradle.ftl" to="${escapeXmlAttribute(projectOut)}/build.gradle"/>

    <merge from="res/values/strings.xml.ftl" to="${escapeXmlAttribute(resOut)}/values/strings.xml"/>

    <!-- 重命名文件 -->
    <instantiate from="assets/xposed_init.ftl" to="${escapeXmlAttribute(manifestOut)}/assets/xposed_init"/>

    <instantiate from="src/app_package/XposedMod.java.ftl" to="${escapeXmlAttribute(srcOut)}/${xposedModClass}.java"/>

    <!-- 打开文件 -->
    <open file="${escapeXmlAttribute(srcOut)}/${xposedModClass}.java"/>

</recipe>
```
xposed_init.ftl 存储的是 Hook类的入口地址

strings.xml.ftl 存储的是 Xpodse模块的描述

XposedMod.java.ftl 创建后的模版代码，可以根据自己的需求，修改模版里面的代码

AndroidManifest.xml.ftl 主要是Xposed的meta字段

build.gradle.ftl 为空

4.bug修复：
由于Xposed会预先加载好jar包，因此，build.gradle中的implements需要修改为provided，才不会出现错误。

具体修改build.gradle.ftl,添加下面依赖:

```
dependencies {
    provided 'de.robv.android.xposed:api:82'
}
```

### 0x02 加入免重启功能
1. 原理分析:原理这里不作多描述,实际上就是通过替换Xposed插件生成的APK，然后通过动态加载的方式来调用，以实现免重启的功能。具体可阅读参考文章。

2. 改进：
 对上面的AS模版进行改造，以实现免重启。
 
``` java
package ${packageName};

import android.app.Application;
import android.content.Context;
import android.content.pm.PackageManager;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import dalvik.system.PathClassLoader;
import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;



public class HookLoader implements IXposedHookLoadPackage {
    /**
     * 当前Xposed模块的包名,方便寻找apk文件
     */
    private final String modulePackage = "${packageName}";

    /**
     * 宿主程序的包名(允许多个),过滤无意义的包名,防止无意义的apk文件加载
     */
    private static List<String> hostAppPackages = new ArrayList<>();

    /**
     * 实际hook逻辑处理类
     */
    private final String handleHookClass = ${xposedModClass}.class.getName();

    /**
     * 实际hook逻辑处理类的入口方法
     */
    private final String handleHookMethod = "handleLoadPackage";

    static {
        // TODO: Add the package name of application your want to hook!
        hostAppPackages.add("${hookPackageName}");
    }

    @Override
    public void handleLoadPackage(final XC_LoadPackage.LoadPackageParam loadPackageParam) throws Throwable {
        if (hostAppPackages.contains(loadPackageParam.packageName)) {
            XposedHelpers.findAndHookMethod(Application.class, "attach", Context.class, new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    Context context=(Context) param.args[0];
                    loadPackageParam.classLoader = context.getClassLoader();
                    invokeHandleHookMethod(context, handleHookClass, handleHookMethod, loadPackageParam);
                }
            });
        }
    }

    /**
     * 安装app以后，通过动态加载这个apk文件，调用相应的方法
     * 从而实现免重启
     * @param context context参数
     * @param handleHookClass   指定由哪一个类处理相关的hook逻辑
     * @param loadPackageParam  传入XC_LoadPackage.LoadPackageParam参数
     * @throws Throwable 抛出各种异常,包括具体hook逻辑的异常,寻找apk文件异常,反射加载Class异常等
     */
    private void invokeHandleHookMethod(Context context, String handleHookClass, String handleHookMethod, XC_LoadPackage.LoadPackageParam loadPackageParam) throws Throwable {

        String apkPath = context.getPackageManager().getApplicationInfo(this.modulePackage,PackageManager.GET_META_DATA).sourceDir;
        PathClassLoader pathClassLoader = new PathClassLoader(apkPath, ClassLoader.getSystemClassLoader());

        Class<?> cls = Class.forName(handleHookClass, true, pathClassLoader);
        Object instance = cls.newInstance();
        Method method = cls.getDeclaredMethod(handleHookMethod, XC_LoadPackage.LoadPackageParam.class);
        method.invoke(instance, loadPackageParam);
    }

}
```

**文章作者是通过区分不同的sdk以实现找到apk的findapk的方法，实际上这里有很简便的方法:
通过系统API便可找到对应的apk路径:**

一行代码即可搞定

```java
String apkPath = context.getPackageManager().getApplicationInfo(this.modulePackage,PackageManager.GET_META_DATA).sourceDir;
```
 

### 0x03 产出
1. XpdModule 需重启
2. XpdFreeRebootModule 免重启


### 参考文章 & 致谢
[Xposed模块开发,免重启改进方案
](https://blog.csdn.net/u011956004/article/details/78612502)

[Xposed Module Template for Android Studio](https://github.com/DVDAndroid/XposedModuleTemplate)

