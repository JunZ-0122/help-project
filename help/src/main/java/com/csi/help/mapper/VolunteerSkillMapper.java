package com.csi.help.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 志愿者技能标签（快速派单匹配）
 */
@Mapper
public interface VolunteerSkillMapper {

    List<String> findSkillCodesByUserId(@Param("userId") String userId);
}
