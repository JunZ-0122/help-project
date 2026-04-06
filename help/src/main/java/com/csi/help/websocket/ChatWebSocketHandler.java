package com.csi.help.websocket;

import com.csi.help.entity.ChatMessage;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private final ObjectMapper objectMapper;
    private final Map<String, Set<WebSocketSession>> userSessions = new ConcurrentHashMap<>();
    private final Map<String, String> sessionUsers = new ConcurrentHashMap<>();

    public ChatWebSocketHandler(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        String userId = getUserId(session);
        if (userId == null || userId.isBlank()) {
            tryClose(session, CloseStatus.NOT_ACCEPTABLE);
            return;
        }

        WebSocketSession safeSession = new ConcurrentWebSocketSessionDecorator(session, 5000, 1024 * 1024);
        userSessions.computeIfAbsent(userId, key -> ConcurrentHashMap.newKeySet()).add(safeSession);
        sessionUsers.put(session.getId(), userId);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        removeSession(session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        removeSession(session);
        tryClose(session, CloseStatus.SERVER_ERROR);
    }

    public void sendChatMessage(ChatMessage message) {
        if (message == null) {
            return;
        }

        if (message.getReceiverId() != null && !message.getReceiverId().isBlank()) {
            sendToUser(message.getReceiverId(), message);
        }
        if (message.getSenderId() != null && !message.getSenderId().isBlank()) {
            sendToUser(message.getSenderId(), message);
        }
    }

    public void sendReadReceipt(String userId, ChatReadReceiptEvent event) {
        if (userId == null || userId.isBlank() || event == null) {
            return;
        }

        sendToUser(userId, event);
    }

    private void sendToUser(String userId, Object payloadObject) {
        Set<WebSocketSession> sessions = userSessions.get(userId);
        if (sessions == null || sessions.isEmpty()) {
            return;
        }

        String payload;
        try {
            payload = objectMapper.writeValueAsString(payloadObject);
        } catch (Exception exception) {
            return;
        }

        TextMessage message = new TextMessage(payload);
        for (WebSocketSession session : sessions) {
            if (session.isOpen()) {
                try {
                    session.sendMessage(message);
                } catch (IOException exception) {
                    removeSession(session);
                }
            } else {
                removeSession(session);
            }
        }
    }

    private String getUserId(WebSocketSession session) {
        Object value = session.getAttributes().get("userId");
        return value instanceof String ? (String) value : null;
    }

    private void removeSession(WebSocketSession session) {
        String userId = sessionUsers.remove(session.getId());
        if (userId == null) {
            return;
        }

        Set<WebSocketSession> sessions = userSessions.get(userId);
        if (sessions == null) {
            return;
        }

        sessions.removeIf(existing -> existing.getId().equals(session.getId()));
        if (sessions.isEmpty()) {
            userSessions.remove(userId);
        }
    }

    private void tryClose(WebSocketSession session, CloseStatus status) {
        try {
            if (session.isOpen()) {
                session.close(status);
            }
        } catch (IOException ignored) {
        }
    }
}
