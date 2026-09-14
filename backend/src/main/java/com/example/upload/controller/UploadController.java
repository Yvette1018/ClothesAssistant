package com.example.upload.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 文件上传控制器
 * 处理HarmonyOS应用上传的照片
 */
@RestController
@CrossOrigin(origins = "*") // 允许跨域请求
public class UploadController {

    // 上传文件保存的目录
    private static final String UPLOAD_DIR = "uploads/";

    /**
     * 处理文件上传请求
     * 
     * @param file 上传的文件
     * @return 上传结果
     */
    @PostMapping("/upload")
    public ResponseEntity<String> uploadFile(@RequestParam("file") MultipartFile file) {
        try {
            // 检查文件是否为空
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body("上传失败：文件为空");
            }

            // 创建上传目录
            File uploadDir = new File(UPLOAD_DIR);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }

            // 生成唯一文件名（时间戳 + 原始文件名）
            String originalFilename = file.getOriginalFilename();
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            String newFilename = timestamp + "_" + (originalFilename != null ? originalFilename : "photo.jpg");
            
            // 保存文件
            Path filePath = Paths.get(UPLOAD_DIR + newFilename);
            Files.write(filePath, file.getBytes());

            System.out.println("文件上传成功：" + filePath.toString());
            System.out.println("文件大小：" + file.getSize() + " bytes");

            // 返回成功响应
            return ResponseEntity.ok("上传成功");

        } catch (IOException e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("上传失败：" + e.getMessage());
        }
    }

    /**
     * 健康检查接口
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("服务运行正常");
    }
}
