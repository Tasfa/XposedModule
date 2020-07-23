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

    <instantiate from="src/app_package/HookLoader.java.ftl" to="${escapeXmlAttribute(srcOut)}/HookLoader.java"/>

    <!-- 打开文件 -->
    <open file="${escapeXmlAttribute(srcOut)}/${xposedModClass}.java"/>

</recipe>