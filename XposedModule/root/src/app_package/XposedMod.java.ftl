package ${packageName};

import android.util.Log;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage;


public class ${xposedModClass} implements IXposedHookLoadPackage {
    private static final String TAG = ${xposedModClass}.class.getName();

    private void hookMultiDex(ClassLoader classLoader) {
        try {
            String className = "";
            String methodName = "";
            Class<?> hookClassName = Class.forName(className, false, classLoader);

            XposedHelpers.findAndHookMethod(hookClassName, methodName, String.class, new XC_MethodHook() {
                @Override
                protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                    super.beforeHookedMethod(param);
                }

                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    super.afterHookedMethod(param);
                }
            });

            /*
            XposedHelpers.findAndHookConstructor(hookClassName,String.class,String.class,String.class, Drawable.class,String.class,boolean.class,Drawable.class,boolean.class, new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    super.afterHookedMethod(param);
                    Log.d(TAG, "p0: " + param.args[0]+" p1: " + param.args[1]+" p2: " + param.args[2]+" p4: " + param.args[4] );
                }
            });
            */

            Log.d(TAG, "Hook end");
        } catch (Exception e) {
            Log.d(TAG, "Hook error : " + e.toString());
            e.printStackTrace();
        }
    }

    @Override
    public void handleLoadPackage(final XC_LoadPackage.LoadPackageParam loadPackageParam) throws Throwable {
        String pkgName = "${hookPackageName}";
        if (loadPackageParam.packageName.equals(pkgName)) {
            Log.d(TAG, "Find and Hook your pkg!!");
            hookMultiDex(loadPackageParam.classLoader);
        }
    }
}