package com.csi.help.service;

import com.csi.help.common.PageResult;
import com.csi.help.entity.ChatMessage;
import com.csi.help.entity.User;
import com.csi.help.mapper.ChatMessageMapper;
import com.csi.help.mapper.UserMapper;
import com.csi.help.websocket.ChatReadReceiptEvent;
import com.csi.help.websocket.ChatWebSocketHandler;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class ChatMessageService {

    private final ChatMessageMapper chatMessageMapper;
    private final UserMapper userMapper;
    private final ChatWebSocketHandler chatWebSocketHandler;

    public ChatMessageService(ChatMessageMapper chatMessageMapper,
                              UserMapper userMapper,
                              ChatWebSocketHandler chatWebSocketHandler) {
        this.chatMessageMapper = chatMessageMapper;
        this.userMapper = userMapper;
        this.chatWebSocketHandler = chatWebSocketHandler;
    }

    @Transactional
    public ChatMessage sendMessage(ChatMessage message) {
        User sender = userMapper.findById(message.getSenderId());
        if (sender != null) {
            message.setSenderName(sender.getName());
            message.setSenderAvatar(sender.getAvatar());
        }

        if (message.getType() == null) {
            message.setType("text");
        }

        message.setIsRead(false);
        chatMessageMapper.insert(message);
        chatWebSocketHandler.sendChatMessage(message);
        return message;
    }

    public PageResult<ChatMessage> getHistory(String requestId, Integer page, Integer pageSize) {
        Long total = chatMessageMapper.countByRequestId(requestId);
        Integer offset = (page - 1) * pageSize;
        List<ChatMessage> messages = chatMessageMapper.findByRequestId(requestId, offset, pageSize);
        return new PageResult<>(messages, total, page, pageSize);
    }

    @Transactional
    public void markAsRead(List<Long> messageIds) {
        if (messageIds == null || messageIds.isEmpty()) {
            return;
        }

        List<ChatMessage> messages = chatMessageMapper.findByIds(messageIds);
        chatMessageMapper.markAsRead(messageIds);
        notifyReadReceipts(messages);
    }

    public Long countUnread(String requestId, String userId) {
        return chatMessageMapper.countUnread(requestId, userId);
    }

    private void notifyReadReceipts(List<ChatMessage> messages) {
        if (messages == null || messages.isEmpty()) {
            return;
        }

        Map<String, ChatReadReceiptEvent> groupedEvents = new LinkedHashMap<>();
        for (ChatMessage message : messages) {
            if (message.getSenderId() == null || message.getSenderId().isBlank()) {
                continue;
            }

            String requestId = message.getRequestId();
            String senderId = message.getSenderId();
            String groupKey = senderId + "::" + requestId;

            ChatReadReceiptEvent event = groupedEvents.get(groupKey);
            if (event == null) {
                event = new ChatReadReceiptEvent();
                event.setRequestId(requestId);
                event.setReaderId(message.getReceiverId());
                event.setMessageIds(new ArrayList<>());
                groupedEvents.put(groupKey, event);
            }

            event.getMessageIds().add(message.getId());
        }

        for (Map.Entry<String, ChatReadReceiptEvent> entry : groupedEvents.entrySet()) {
            String senderId = entry.getKey().split("::", 2)[0];
            chatWebSocketHandler.sendReadReceipt(senderId, entry.getValue());
        }
    }
}
