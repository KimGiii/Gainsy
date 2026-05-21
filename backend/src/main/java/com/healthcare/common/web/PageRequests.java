package com.healthcare.common.web;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

/**
 * 컨트롤러에서 클라이언트가 전달한 `page`, `size`를 안전하게 Pageable로 변환한다.
 *
 * <p>악의적인 클라이언트가 `size=1000000`을 보내 DB/메모리를 과부하시키는 것을 방지하기 위해
 * 모든 페이지 크기는 {@link #MAX_PAGE_SIZE}로 상한 처리한다.
 * 음수 page/size는 0/{@link #DEFAULT_PAGE_SIZE}로 보정한다.
 */
public final class PageRequests {

    public static final int MAX_PAGE_SIZE = 100;
    public static final int DEFAULT_PAGE_SIZE = 20;

    private PageRequests() {}

    public static Pageable of(int page, int size) {
        return PageRequest.of(safePage(page), safeSize(size));
    }

    public static Pageable of(int page, int size, Sort sort) {
        return PageRequest.of(safePage(page), safeSize(size), sort);
    }

    public static int safeSize(int size) {
        if (size <= 0) {
            return DEFAULT_PAGE_SIZE;
        }
        return Math.min(size, MAX_PAGE_SIZE);
    }

    public static int safePage(int page) {
        return Math.max(page, 0);
    }
}
