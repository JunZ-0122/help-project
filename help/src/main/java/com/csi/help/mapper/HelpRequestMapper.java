package com.csi.help.mapper;

import com.csi.help.entity.HelpRequest;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 求助请求 Mapper
 */
@Mapper
public interface HelpRequestMapper {
    
    /**
     * 插入求助请求
     */
    int insert(HelpRequest request);
    
    /**
     * 根据 ID 查询
     */
    HelpRequest findById(@Param("id") String id);
    
    /**
     * 分页查询求助列表
     */
    List<HelpRequest> findByPage(@Param("type") String type,
                                   @Param("status") String status,
                                   @Param("urgency") String urgency,
                                   @Param("offset") Integer offset,
                                   @Param("pageSize") Integer pageSize);
    
    /**
     * 统计总数
     */
    Long countByCondition(@Param("type") String type,
                          @Param("status") String status,
                          @Param("urgency") String urgency);
    
    /**
     * 查询用户的求助列表
     */
    List<HelpRequest> findByUserId(@Param("userId") String userId,
                                     @Param("offset") Integer offset,
                                     @Param("pageSize") Integer pageSize);

    /**
     * 当前用户最近更新的求助（首页「最近求助」）
     */
    List<HelpRequest> findRecentByUserId(@Param("userId") String userId,
                                         @Param("limit") int limit);
    
    /**
     * 统计用户的求助数量
     */
    Long countByUserId(@Param("userId") String userId);
    
    /**
     * 更新求助请求
     */
    int update(HelpRequest request);
    
    /**
     * 更新状态
     */
    int updateStatus(@Param("id") String id, @Param("status") String status);
    
    /**
     * 分配志愿者
     */
    int assignVolunteer(@Param("id") String id,
                        @Param("volunteerId") String volunteerId,
                        @Param("volunteerName") String volunteerName);
    
    /**
     * 删除（软删除，更新状态为 cancelled）
     */
    int delete(@Param("id") String id);
    
    /**
     * 查询所有求助请求（分页）
     */
    List<HelpRequest> findAll(@Param("offset") Integer offset,
                               @Param("pageSize") Integer pageSize,
                               @Param("status") String status);
    
    /**
     * 统计求助请求数量（按状态）
     */
    Long count(@Param("status") String status);

    /**
     * 社区求助管理列表：all=排除已取消；pending；assigned_open=已分配或进行中
     */
    List<HelpRequest> findAllCommunity(@Param("offset") Integer offset,
                                       @Param("pageSize") Integer pageSize,
                                       @Param("listScope") String listScope);

    Long countCommunity(@Param("listScope") String listScope);

    /**
     * \u5df2\u521b\u5efa\u6c42\u52a9\u6309\u7c7b\u578b\u7edf\u8ba1\uff08\u4e0d\u542b\u5df2\u53d6\u6d88\uff09
     */
    List<Map<String, Object>> countByTypeCreatedBetween(@Param("start") LocalDateTime start,
                                                        @Param("end") LocalDateTime end);

    /**
     * 查询待接单且已有经纬度的求助（用于附近求助排序）
     */
    List<HelpRequest> findPendingWithLocation(@Param("offset") int offset, @Param("limit") int limit);

    /**
     * 待分配求助（快速派单推荐）
     */
    List<HelpRequest> findAllPendingForDispatch(@Param("limit") int limit);
}
