package com.csi.help.controller;

import com.csi.help.common.PageResult;
import com.csi.help.common.Result;
import com.csi.help.entity.ChatMessage;
import com.csi.help.service.ChatMessageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 聊天消息控制器
 */
@RestController
@RequestMapping("/api/chat")
public class  ChatMessageController {

    @Autowired
    private ChatMessageService chatMessageService;

    /**
     * 发送消息
     */
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
    @PutMapping("/read")
    public Result<Void> markAsRead(@RequestBody Map<String, List<Long>> params) {
        List<Long> messageIds = params.get("messageIds");
        chatMessageService.markAsRead(messageIds);
        return Result.success();
    }

    /**
     * 获取未读消息数量
     */
    @GetMapping("/{requestId}/unread")
    public Result<Long> countUnread(@PathVariable String requestId,
                                      @RequestAttribute("userId") String userId) {
        Long count = chatMessageService.countUnread(requestId, userId);
        return Result.success(count);
    }
}
