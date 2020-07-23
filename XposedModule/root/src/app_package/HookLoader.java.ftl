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