/**
 * 小红书收藏数据提取器
 * 用于在WebView中提取用户收藏的笔记数据
 */

class RedBookDataExtractor {
    constructor() {
        this.isExtracting = false;
        this.isPaused = false;
        this.extractedData = [];
        this.currentPage = 1;
        this.totalCount = 0;
        this.extractedCount = 0;
        this.maxRetries = 3;
        this.retryCount = 0;
        this.extractionDelay = 1500; // 增加延迟避免被限制
        this.scrollDelay = 2000; // 滚动延迟
        
        this.initializeExtractor();
    }
    
    initializeExtractor() {
        // 监听页面变化
        this.observePageChanges();
        
        // 发送初始化完成消息
        this.sendMessageToApp({
            type: 'initialized',
            message: '数据提取器已初始化'
        });
        
        console.log('小红书数据提取器已初始化');
    }
    
    // 开始数据提取
    startExtraction() {
        if (this.isExtracting) {
            console.log('数据提取已在进行中');
            return;
        }
        
        this.isExtracting = true;
        this.isPaused = false;
        this.extractedData = [];
        this.currentPage = 1;
        this.extractedCount = 0;
        this.retryCount = 0;
        
        console.log('开始提取收藏数据...');
        
        // 检查是否在收藏页面
        if (!this.isOnCollectionPage()) {
            this.sendMessageToApp({
                type: 'error',
                message: '请先导航到收藏夹页面'
            });
            this.isExtracting = false;
            return;
        }
        
        // 发送开始消息
        this.sendMessageToApp({
            type: 'progress',
            total: 0,
            current: 0
        });
        
        // 开始提取流程
        setTimeout(() => {
            this.extractCurrentPage();
        }, 1000);
    }
    
    // 暂停提取
    pauseExtraction() {
        this.isPaused = true;
        this.sendMessageToApp({
            type: 'paused',
            message: '数据提取已暂停'
        });
        console.log('数据提取已暂停');
    }
    
    // 恢复提取
    resumeExtraction() {
        if (!this.isExtracting) return;
        
        this.isPaused = false;
        this.sendMessageToApp({
            type: 'resumed',
            message: '数据提取已恢复'
        });
        console.log('数据提取已恢复');
        
        setTimeout(() => {
            this.extractCurrentPage();
        }, 500);
    }
    
    // 停止提取
    stopExtraction() {
        this.isExtracting = false;
        this.isPaused = false;
        
        this.sendMessageToApp({
            type: 'stopped',
            message: '数据提取已停止'
        });
        console.log('数据提取已停止');
    }
    
    // 检查是否在收藏页面
    isOnCollectionPage() {
        const url = window.location.href;
        const hasCollectionInUrl = url.includes('/collect') || 
                                  url.includes('/collection') ||
                                  url.includes('/liked');
        
        const hasCollectionElements = document.querySelector('.collection-container, [data-testid="collection"], .note-item, .feeds-container') !== null;
        
        const hasCollectionTitle = document.title.includes('收藏') || 
                                  document.title.includes('喜欢') ||
                                  document.querySelector('h1, h2, h3')?.textContent?.includes('收藏');
        
        console.log('页面检查:', {
            url: url,
            hasCollectionInUrl: hasCollectionInUrl,
            hasCollectionElements: hasCollectionElements,
            hasCollectionTitle: hasCollectionTitle
        });
        
        return hasCollectionInUrl || hasCollectionElements || hasCollectionTitle;
    }
    
    // 提取当前页面数据
    async extractCurrentPage() {
        if (!this.isExtracting || this.isPaused) return;
        
        try {
            console.log('开始提取当前页面数据...');
            
            // 等待页面加载完成
            await this.waitForPageLoad();
            
            // 获取当前页面的笔记元素
            const noteElements = this.findNoteElements();
            
            console.log(`找到 ${noteElements.length} 个笔记元素`);
            
            if (noteElements.length === 0) {
                if (this.retryCount < this.maxRetries) {
                    this.retryCount++;
                    console.log(`未找到笔记元素，重试 ${this.retryCount}/${this.maxRetries}`);
                    setTimeout(() => this.extractCurrentPage(), 3000);
                    return;
                } else {
                    console.log('达到最大重试次数，完成提取');
                    this.completeExtraction();
                    return;
                }
            }
            
            // 重置重试计数
            this.retryCount = 0;
            
            // 更新总数（首次估算）
            if (this.totalCount === 0) {
                this.estimateTotalCount();
            }
            
            // 提取每个笔记的数据
            for (let i = 0; i < noteElements.length; i++) {
                if (!this.isExtracting || this.isPaused) break;
                
                try {
                    const element = noteElements[i];
                    const noteData = this.extractNoteData(element);
                    
                    if (noteData && !this.isDuplicate(noteData)) {
                        this.extractedData.push(noteData);
                        this.extractedCount++;
                        
                        console.log(`提取到笔记: ${noteData.title}`);
                        
                        // 发送单个数据
                        this.sendMessageToApp({
                            type: 'data',
                            data: noteData
                        });
                        
                        // 更新进度
                        this.sendProgressUpdate();
                    }
                } catch (error) {
                    console.error('提取单个笔记数据失败:', error);
                }
                
                // 添加延迟避免过于频繁
                await this.sleep(100);
            }
            
            // 尝试加载下一页
            setTimeout(async () => {
                await this.loadNextPage();
            }, this.extractionDelay);
            
        } catch (error) {
            console.error('提取数据时出错:', error);
            this.sendMessageToApp({
                type: 'error',
                message: `数据提取失败: ${error.message}`
            });
        }
    }
    
    // 查找笔记元素
    findNoteElements() {
        // 尝试多种选择器，适应不同版本的页面结构
        const selectors = [
            '.note-item',
            '.collection-item',
            '[data-testid="note-item"]',
            '.feeds-page .note-item',
            '.col .cover',
            'section .note-item',
            '.note-card',
            '.item',
            '.noteItem',
            'a[href*="/explore/"]',
            'a[href*="/discovery/item/"]'
        ];
        
        for (const selector of selectors) {
            const elements = document.querySelectorAll(selector);
            if (elements.length > 0) {
                console.log(`找到 ${elements.length} 个笔记元素，使用选择器: ${selector}`);
                return Array.from(elements);
            }
        }
        
        // 备用方案：通过图片查找
        console.log('使用备用方案查找笔记元素...');
        const images = document.querySelectorAll('img[src*="ci.xiaohongshu.com"], img[src*="sns-img"], img[src*="xhscdn.com"]');
        const imageParents = Array.from(images)
            .map(img => {
                // 向上查找可能的笔记容器
                let parent = img.parentElement;
                for (let i = 0; i < 5 && parent; i++) {
                    if (parent.tagName === 'A' || 
                        parent.querySelector('a[href*="explore"]') ||
                        parent.classList.toString().includes('note') ||
                        parent.classList.toString().includes('item')) {
                        return parent;
                    }
                    parent = parent.parentElement;
                }
                return img.closest('a') || img.parentElement;
            })
            .filter(Boolean);
        
        console.log(`备用方案找到 ${imageParents.length} 个可能的笔记元素`);
        return imageParents;
    }
    
    // 提取单个笔记数据
    extractNoteData(element) {
        try {
            const data = {
                id: this.extractId(element),
                title: this.extractTitle(element),
                content: this.extractContent(element),
                imageURL: this.extractImageURL(element),
                url: this.extractURL(element),
                authorName: this.extractAuthorName(element),
                authorAvatar: this.extractAuthorAvatar(element),
                tags: this.extractTags(element)
            };
            
            // 验证必要字段
            if (!data.id || !data.title || !data.url) {
                console.warn('笔记数据不完整:', data);
                return null;
            }
            
            return data;
            
        } catch (error) {
            console.error('提取笔记数据失败:', error);
            return null;
        }
    }
    
    // 提取笔记ID
    extractId(element) {
        // 从URL中提取ID
        const linkElement = element.tagName === 'A' ? element : element.querySelector('a');
        if (linkElement && linkElement.href) {
            const match = linkElement.href.match(/\/explore\/([a-f0-9]+)/i) ||
                         linkElement.href.match(/\/discovery\/item\/([a-f0-9]+)/i) ||
                         linkElement.href.match(/\/notes\/([a-f0-9]+)/i);
            if (match) return match[1];
        }
        
        // 从data属性中提取
        const dataId = element.getAttribute('data-id') || 
                      element.getAttribute('data-note-id') ||
                      element.querySelector('[data-id]')?.getAttribute('data-id');
        if (dataId) return dataId;
        
        // 生成临时ID
        const timestamp = Date.now();
        const random = Math.random().toString(36).substr(2, 9);
        return `${timestamp}_${random}`;
    }
    
    // 提取标题
    extractTitle(element) {
        const titleSelectors = [
            '.title',
            '.note-title',
            '.item-title',
            'h1', 'h2', 'h3', 'h4',
            '.text-content',
            '.desc',
            '.content'
        ];
        
        for (const selector of titleSelectors) {
            const titleElement = element.querySelector(selector);
            if (titleElement && titleElement.textContent.trim()) {
                return titleElement.textContent.trim();
            }
        }
        
        // 备用方案：从图片alt属性获取
        const img = element.querySelector('img');
        if (img && img.alt && img.alt.length > 1) {
            return img.alt.trim();
        }
        
        // 最后备用：使用链接文本
        const linkText = element.textContent?.trim();
        if (linkText && linkText.length > 3) {
            return linkText.substring(0, 50);
        }
        
        return '未知标题';
    }
    
    // 提取内容描述
    extractContent(element) {
        const contentSelectors = [
            '.desc',
            '.description',
            '.content',
            '.note-content',
            'p'
        ];
        
        for (const selector of contentSelectors) {
            const contentElement = element.querySelector(selector);
            if (contentElement && contentElement.textContent.trim()) {
                return contentElement.textContent.trim();
            }
        }
        
        return null;
    }
    
    // 提取图片URL
    extractImageURL(element) {
        const img = element.querySelector('img');
        if (img) {
            return img.src || img.getAttribute('data-src') || img.getAttribute('data-original');
        }
        return null;
    }
    
    // 提取原文链接
    extractURL(element) {
        const linkElement = element.tagName === 'A' ? element : element.querySelector('a');
        if (linkElement && linkElement.href) {
            // 确保是完整URL
            if (linkElement.href.startsWith('http')) {
                return linkElement.href;
            } else if (linkElement.href.startsWith('/')) {
                return `https://www.xiaohongshu.com${linkElement.href}`;
            }
        }
        return window.location.href;
    }
    
    // 提取作者名称
    extractAuthorName(element) {
        const authorSelectors = [
            '.author',
            '.author-name',
            '.user-name',
            '.username',
            '[class*="author"]',
            '[class*="user"]'
        ];
        
        for (const selector of authorSelectors) {
            const authorElement = element.querySelector(selector);
            if (authorElement && authorElement.textContent.trim()) {
                return authorElement.textContent.trim();
            }
        }
        
        return null;
    }
    
    // 提取作者头像
    extractAuthorAvatar(element) {
        const avatarImg = element.querySelector('.avatar img, .user-avatar img, [class*="avatar"] img');
        if (avatarImg) {
            return avatarImg.src || avatarImg.getAttribute('data-src');
        }
        return null;
    }
    
    // 提取标签
    extractTags(element) {
        const tags = [];
        const tagElements = element.querySelectorAll('.tag, .hashtag, [class*="tag"]');
        
        tagElements.forEach(tagElement => {
            const tagText = tagElement.textContent.trim();
            if (tagText && !tags.includes(tagText)) {
                tags.push(tagText);
            }
        });
        
        return tags;
    }
    
    // 检查是否重复
    isDuplicate(noteData) {
        return this.extractedData.some(existing => existing.id === noteData.id);
    }
    
    // 估算总数
    estimateTotalCount() {
        // 尝试从页面信息中获取总数
        const countElements = document.querySelectorAll('.count, .total, [class*="count"], [class*="total"]');
        
        for (const element of countElements) {
            const text = element.textContent;
            const match = text.match(/(\d+)/);
            if (match) {
                const count = parseInt(match[1]);
                if (count > 0 && count < 100000) {
                    this.totalCount = count;
                    console.log(`估算总数: ${count}`);
                    return;
                }
            }
        }
        
        // 备用估算：基于当前可见元素
        const visibleElements = this.findNoteElements();
        this.totalCount = Math.max(visibleElements.length * 3, 20); // 估算为可见元素的3倍
        console.log(`备用估算总数: ${this.totalCount}`);
    }
    
    // 加载下一页
    async loadNextPage() {
        if (!this.isExtracting || this.isPaused) return;
        
        const initialCount = this.findNoteElements().length;
        
        // 尝试点击加载更多按钮
        if (await this.tryClickLoadMore()) {
            console.log('点击了加载更多按钮');
            await this.sleep(this.scrollDelay);
        } else {
            // 尝试滚动加载
            console.log('尝试滚动加载更多内容');
            await this.tryScrollLoad();
        }
        
        // 等待新内容加载
        await this.sleep(this.scrollDelay);
        
        const newCount = this.findNoteElements().length;
        
        if (newCount > initialCount) {
            console.log(`加载了新内容，从 ${initialCount} 增加到 ${newCount}`);
            this.currentPage++;
            // 继续提取新加载的内容
            this.extractCurrentPage();
        } else {
            console.log('没有更多内容，完成提取');
            this.completeExtraction();
        }
    }
    
    // 尝试点击加载更多按钮
    async tryClickLoadMore() {
        const loadMoreSelectors = [
            'button[class*="load"]',
            'button[class*="more"]',
            '.load-more',
            '.btn-load',
            'button:contains("更多")',
            'button:contains("加载")',
            '[class*="load-more"]'
        ];
        
        for (const selector of loadMoreSelectors) {
            const button = document.querySelector(selector);
            if (button && button.offsetParent !== null) {
                button.click();
                return true;
            }
        }
        
        return false;
    }
    
    // 尝试滚动加载
    async tryScrollLoad() {
        const scrollHeight = document.documentElement.scrollHeight;
        
        // 滚动到底部
        window.scrollTo({
            top: scrollHeight,
            behavior: 'smooth'
        });
        
        await this.sleep(1000);
        
        // 触发更多滚动事件
        for (let i = 0; i < 3; i++) {
            window.scrollBy(0, 100);
            await this.sleep(300);
        }
    }
    
    // 完成提取
    completeExtraction() {
        this.isExtracting = false;
        
        console.log(`数据提取完成，共获取 ${this.extractedCount} 条记录`);
        
        this.sendMessageToApp({
            type: 'complete',
            message: `提取完成，共获取 ${this.extractedCount} 条记录`,
            total: this.extractedCount
        });
    }
    
    // 发送进度更新
    sendProgressUpdate() {
        this.sendMessageToApp({
            type: 'progress',
            total: this.totalCount,
            current: this.extractedCount
        });
    }
    
    // 等待页面加载
    waitForPageLoad() {
        return new Promise(resolve => {
            if (document.readyState === 'complete') {
                resolve();
            } else {
                window.addEventListener('load', resolve, { once: true });
                // 超时保护
                setTimeout(resolve, 5000);
            }
        });
    }
    
    // 监听页面变化
    observePageChanges() {
        // 监听URL变化
        let currentUrl = window.location.href;
        
        const observer = new MutationObserver(() => {
            if (window.location.href !== currentUrl) {
                currentUrl = window.location.href;
                console.log('页面URL已变化:', currentUrl);
                
                // 如果正在提取且离开了收藏页面，停止提取
                if (this.isExtracting && !this.isOnCollectionPage()) {
                    this.stopExtraction();
                }
            }
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
    
    // 发送消息到应用
    sendMessageToApp(message) {
        try {
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.dataExtractor) {
                window.webkit.messageHandlers.dataExtractor.postMessage(message);
            } else {
                console.log('发送消息到应用:', message);
            }
        } catch (error) {
            console.error('发送消息失败:', error);
        }
    }
    
    // 延迟函数
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    
    // 获取统计信息
    getStatistics() {
        return {
            isExtracting: this.isExtracting,
            isPaused: this.isPaused,
            totalCount: this.totalCount,
            extractedCount: this.extractedCount,
            currentPage: this.currentPage
        };
    }
}

// 创建全局实例
window.RedBookDataExtractor = new RedBookDataExtractor();

// 兼容性处理
if (typeof window !== 'undefined') {
    window.RedBookDataExtractor = window.RedBookDataExtractor || new RedBookDataExtractor();
    
    // 页面加载完成后通知
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            console.log('DOM加载完成，数据提取器已准备就绪');
        });
    }
} 