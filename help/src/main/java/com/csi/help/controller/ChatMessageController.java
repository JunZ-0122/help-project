package com.csi.help.controller;

import com.csi.help.common.PageResult;
import com.csi.help.common.Result;
import com.csi.help.config.OpenApiConfig;
import com.csi.help.entity.ChatMessage;
import com.csi.help.service.ChatMessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 聊天消息控制器
 */
@RestController
@RequestMapping("/api/chat")
@Tag(name = "聊天")
@SecurityRequirement(name = OpenApiConfig.SECURITY_SCHEME_NAME)
public class  ChatMessageController {

    @Autowired
    private ChatMessageService chatMessageService;

    /**
     * 发送消息
     */
    @Operation(summary = "发送聊天消息")
    @PostMapping("/")
    public Result<ChatMessage> sendMessage(@RequestBody ChatMessage message,
                                             @RequestAttribute("userId") String senderId) {
        message.setSenderId(senderId);
        ChatMessage savedMessage = chatMessageService.sendMessage(message);

        return Result.success(savedMessage);
    }

    /**
     * 获取聊天历史
     */
    @Operation(summary = "获取聊天历史")
    @GetMapping("/{requestId}")
    public Result<PageResult<ChatMessage>> getHistory(@PathVariable String requestId,
                                                        @RequestParam(defaultValue = "1") Integer page,
                                                        @RequestParam(defaultValue = "50") Integer pageSize) {
        PageResult<ChatMessage> result = chatMessageService.getHistory(requestId, page, pageSize);
        return Result.success(result);
    }

    /**
     * 标记消息为已读
     */
    @Operation(summary = "批量标记消息已读")
    @PutMapping("/read")
    public Result<Void> markAsRead(@RequestBody Map<String, List<Long>> params) {
        List<Long> messageIds = params.get("messageIds");
        chatMessageService.markAsRead(messageIds);
        return Result.success();
    }

    /**
     * 获取未读消息数量
     */
    @Operation(summary = "获取未读消息数")
    @GetMapping("/{requestId}/unread")
    public Result<Long> countUnread(@PathVariable String requestId,
                                      @RequestAttribute("userId") String userId) {
        Long count = chatMessageService.countUnread(requestId, userId);
        return Result.success(count);
    }
}
