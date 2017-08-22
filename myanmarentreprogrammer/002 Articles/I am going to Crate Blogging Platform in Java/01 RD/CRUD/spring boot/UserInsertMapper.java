package com.example.msp.domain.user.mapper;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Options;

import com.example.msp.domain.user.entity.UserEntity;

@Mapper
public interface UserInsertMapper {

	String INSERT = "insert into users(name) values(#{name,jdbcType=VARCHAR})";

	@Insert(INSERT)
	@Options(useGeneratedKeys = true, keyProperty = "id", keyColumn="id")
	//@SelectKey(statement = "CALL IDENTITY()", before = false, keyProperty = "id", resultType = short.class)
	int insertUser(UserEntity user);
}
