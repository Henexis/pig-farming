let dashboard = document.getElementById('dashboard');
let pigCount = document.getElementById('pig-count');
let pigsContainer = document.getElementById('pigs-container');
let closeBtn = document.getElementById('close-btn');

let config = {
    growthTime: 10, // phút
    feedTime: 2,    // phút
    waterTime: 3,   // phút
    cleanTime: 5    // phút
};

let pigs = [];
let updateInterval;

// Lắng nghe tin nhắn từ client
window.addEventListener('message', function(event) {
    let data = event.data;
    
    if (data.action === 'openDashboard') {
        dashboard.style.display = 'block';
        pigs = data.pigs;
        config = data.config;
        renderPigs();
        
        // Cập nhật timer mỗi giây
        if (updateInterval) clearInterval(updateInterval);
        updateInterval = setInterval(updateTimers, 1000);
    }
    
    if (data.action === 'updatePigs') {
        pigs = data.pigs;
        renderPigs();
    }
});

// Đóng dashboard
closeBtn.addEventListener('click', function() {
    dashboard.style.display = 'none';
    if (updateInterval) clearInterval(updateInterval);
    fetch('https://pig-farming/closeDashboard', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
});

// Render danh sách lợn
function renderPigs() {
    pigsContainer.innerHTML = '';
    pigCount.textContent = pigs.length;
    
    pigs.forEach(pig => {
        // Tính phần trăm tăng trưởng
        const now = Math.floor(Date.now() / 1000);
        const growthTimeInSeconds = config.growthTime * 60;
        const growthPercent = Math.min(100, ((now - pig.bornTime) / growthTimeInSeconds) * 100);
        
        // Tính thời gian còn lại
        const timeRemaining = Math.max(0, growthTimeInSeconds - (now - pig.bornTime));
        
        // Tính các chỉ số
        const timeSinceLastFed = now - pig.lastFed;
        const timeSinceLastWatered = now - pig.lastWatered;
        const timeSinceLastCleaned = now - pig.lastCleaned;
        
        const hungerPercent = Math.max(0, pig.hunger - (timeSinceLastFed / (config.feedTime * 60)) * 100);
        const thirstPercent = Math.max(0, pig.thirst - (timeSinceLastWatered / (config.waterTime * 60)) * 100);
        const cleanlinessPercent = Math.max(0, pig.cleanliness - (timeSinceLastCleaned / (config.cleanTime * 60)) * 100);
        
        // Tạo thẻ lợn
        const pigCard = document.createElement('div');
        pigCard.className = 'pig-card';
        
        // Hiển thị nhãn nếu lợn đã sẵn sàng thu hoạch
        if (growthPercent >= 100) {
            const readyLabel = document.createElement('div');
            readyLabel.className = 'pig-ready';
            readyLabel.textContent = 'Sẵn sàng thu hoạch';
            pigCard.appendChild(readyLabel);
        }
        
        // Tiêu đề
        const title = document.createElement('h3');
        title.textContent = `Lợn #${pig.id} - ${pig.weight}kg`;
        pigCard.appendChild(title);
        
        // Chi tiết
        const details = document.createElement('div');
        details.className = 'pig-details';
        
        const bornDate = new Date(pig.bornTime * 1000);
        details.innerHTML = `
            <p>Ngày sinh: ${bornDate.toLocaleString('vi-VN')}</p>
            <p>Trọng lượng: ${pig.weight} kg</p>
        `;
        pigCard.appendChild(details);
        
        // Trạng thái
        const status = document.createElement('div');
        status.className = 'pig-status';
        
        // Tăng trưởng
        const growthStatus = document.createElement('div');
        growthStatus.innerHTML = `
            <div class="status-label">
                <span>Tăng trưởng</span>
                <span>${Math.floor(growthPercent)}%</span>
            </div>
            <div class="status-bar">
                <div class="progress progress-growth" style="width: ${growthPercent}%"></div>
            </div>
            <div class="timer" id="growth-timer-${pig.id}">
                ${formatTime(timeRemaining)} còn lại
            </div>
        `;
        status.appendChild(growthStatus);
        
        // Đói
        const hungerStatus = document.createElement('div');
        hungerStatus.innerHTML = `
            <div class="status-label">
                <span>Độ đói</span>
                <span>${Math.floor(hungerPercent)}%</span>
            </div>
            <div class="status-bar">
                <div class="progress progress-hunger" style="width: ${hungerPercent}%"></div>
            </div>
            <div class="timer" id="hunger-timer-${pig.id}">
                ${formatTime(config.feedTime * 60 * (hungerPercent / 100))} đến khi đói
            </div>
        `;
        status.appendChild(hungerStatus);
        
        // Khát
        const thirstStatus = document.createElement('div');
        thirstStatus.innerHTML = `
            <div class="status-label">
                <span>Độ khát</span>
                <span>${Math.floor(thirstPercent)}%</span>
            </div>
            <div class="status-bar">
                <div class="progress progress-thirst" style="width: ${thirstPercent}%"></div>
            </div>
            <div class="timer" id="thirst-timer-${pig.id}">
                ${formatTime(config.waterTime * 60 * (thirstPercent / 100))} đến khi khát
            </div>
        `;
        status.appendChild(thirstStatus);
        
        // Độ sạch
        const cleanlinessStatus = document.createElement('div');
        cleanlinessStatus.innerHTML = `
            <div class="status-label">
                <span>Độ sạch</span>
                <span>${Math.floor(cleanlinessPercent)}%</span>
            </div>
            <div class="status-bar">
                <div class="progress progress-cleanliness" style="width: ${cleanlinessPercent}%"></div>
            </div>
            <div class="timer" id="cleanliness-timer-${pig.id}">
                ${formatTime(config.cleanTime * 60 * (cleanlinessPercent / 100))} đến khi bẩn
            </div>
        `;
        status.appendChild(cleanlinessStatus);
        
        pigCard.appendChild(status);
        pigsContainer.appendChild(pigCard);
    });
}

// Cập nhật timers
function updateTimers() {
    const now = Math.floor(Date.now() / 1000);
    
    pigs.forEach(pig => {
        // Tính thời gian còn lại đến khi lợn trưởng thành
        const growthTimeInSeconds = config.growthTime * 60;
        const timeRemaining = Math.max(0, growthTimeInSeconds - (now - pig.bornTime));
        const growthTimer = document.getElementById(`growth-timer-${pig.id}`);
        if (growthTimer) {
            if (timeRemaining <= 0) {
                growthTimer.textContent = `Đã trưởng thành`;
            } else {
                growthTimer.textContent = `${formatTime(timeRemaining)} còn lại`;
            }
        }
        
        // Tính thời gian đến khi đói
        const timeSinceLastFed = now - pig.lastFed;
        const hungerPercent = Math.max(0, pig.hunger - (timeSinceLastFed / (config.feedTime * 60)) * 100);
        const hungerTimeRemaining = config.feedTime * 60 * (hungerPercent / 100);
        const hungerTimer = document.getElementById(`hunger-timer-${pig.id}`);
        if (hungerTimer) {
            if (hungerPercent <= 0) {
                hungerTimer.textContent = `Đang đói`;
            } else {
                hungerTimer.textContent = `${formatTime(hungerTimeRemaining)} đến khi đói`;
            }
        }
        
        // Tính thời gian đến khi khát
        const timeSinceLastWatered = now - pig.lastWatered;
        const thirstPercent = Math.max(0, pig.thirst - (timeSinceLastWatered / (config.waterTime * 60)) * 100);
        const thirstTimeRemaining = config.waterTime * 60 * (thirstPercent / 100);
        const thirstTimer = document.getElementById(`thirst-timer-${pig.id}`);
        if (thirstTimer) {
            if (thirstPercent <= 0) {
                thirstTimer.textContent = `Đang khát`;
            } else {
                thirstTimer.textContent = `${formatTime(thirstTimeRemaining)} đến khi khát`;
            }
        }
        
        // Tính thời gian đến khi bẩn
        const timeSinceLastCleaned = now - pig.lastCleaned;
        const cleanlinessPercent = Math.max(0, pig.cleanliness - (timeSinceLastCleaned / (config.cleanTime * 60)) * 100);
        const cleanlinessTimeRemaining = config.cleanTime * 60 * (cleanlinessPercent / 100);
        const cleanlinessTimer = document.getElementById(`cleanliness-timer-${pig.id}`);
        if (cleanlinessTimer) {
            if (cleanlinessPercent <= 0) {
                cleanlinessTimer.textContent = `Cần tắm rửa`;
            } else {
                cleanlinessTimer.textContent = `${formatTime(cleanlinessTimeRemaining)} đến khi bẩn`;
            }
        }
    });
}

// Định dạng thời gian từ giây sang giờ:phút:giây
function formatTime(seconds) {
    seconds = Math.floor(seconds);
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) {
        return `${hours}h ${minutes}p ${secs}s`;
    } else if (minutes > 0) {
        return `${minutes}p ${secs}s`;
    } else {
        return `${secs}s`;
    }
}

// Xử lý sự kiện phím tắt để đóng UI
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        dashboard.style.display = 'none';
        if (updateInterval) clearInterval(updateInterval);
        fetch('https://pig-farming/closeDashboard', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
});
