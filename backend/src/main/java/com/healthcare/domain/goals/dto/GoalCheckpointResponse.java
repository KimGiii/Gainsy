package com.healthcare.domain.goals.dto;

import com.healthcare.domain.goals.entity.GoalCheckpoint;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GoalCheckpointResponse {

    private LocalDate checkpointDate;
    private BigDecimal actualValue;
    private BigDecimal projectedValue;
    private Boolean isOnTrack;
    /** "시작" — 목표 생성 시 자동 기록된 시작 체크포인트, null — 주간(일요일) 자동 체크포인트. */
    private String notes;

    public static GoalCheckpointResponse from(GoalCheckpoint checkpoint) {
        return GoalCheckpointResponse.builder()
                .checkpointDate(checkpoint.getCheckpointDate())
                .actualValue(checkpoint.getActualValue())
                .projectedValue(checkpoint.getProjectedValue())
                .isOnTrack(checkpoint.getIsOnTrack())
                .notes(checkpoint.getNotes())
                .build();
    }
}
