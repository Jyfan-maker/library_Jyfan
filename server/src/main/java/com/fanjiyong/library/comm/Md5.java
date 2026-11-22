package com.fanjiyong.library.comm;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * MD5 工具类：把明文密码转成 32 位小写十六进制密文。
 * 数据库只存密文，登录时服务端先加密再与库中密文比对。
 * 注意：MD5 仅用于本课程设计要求，真实系统应使用加盐哈希（bcrypt 等）。
 */
public final class Md5 {

    private Md5() {
    }

    public static String md5(String text) {
        if (text == null) {
            return "";
        }
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] bytes = md.digest(text.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(32);
            for (byte b : bytes) {
                sb.append(String.format("%02x", b & 0xff));
            }
            return sb.toString();
        } catch (Exception e) {
            throw new IllegalStateException("MD5 计算失败", e);
        }
    }
}
