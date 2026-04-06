package com.csi.help.mapper;

import com.csi.help.entity.ChatMessage;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface ChatMessageMapper {

    int insert(ChatMessage message);

    List<ChatMessage> findByRequestId(@Param("requestId") String requestId,
                                      @Param("offset") Integer offset,
                                      @Param("pageSize") Integer pageSize);

    Long countByRequestId(@Param("requestId") String requestId);

    List<ChatMessage> findByIds(@Param("messageIds") List<Long> messageIds);

    int markAsRead(@Param("messageIds") List<Long> messageIds);

    Long countUnread(@Param("requestId") String requestId, @Param("userId") String userId);
}
