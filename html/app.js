window.addEventListener('message', function(event) {
    if (event.data.action === 'openDashboard') {
        document.getElementById('dashboard').style.display = 'block';
        updatePigList(event.data.pigs, event.data.config);
    } else if (event.data.action === 'updatePigs') {
        updatePigList(event.data.pigs);
    }
});

function updatePigList(pigs, config) {
    const pigList = document.getElementById('pig-list');
    pigList.innerHTML = '';

    pigs.forEach(pig => {
        const growthPercent = Math.min(100, Math.floor((Date.now() / 1000 - pig.bornTime) / (config.growthTime * 60) * 100));
        const status = growthPercent >= 100 ? 'Đã trưởng thành' : `Đang lớn: ${growthPercent}%`;

        const pigElement = document.createElement('div');
        pigElement.innerHTML = `
            <h3>Lợn #${pig.id}</h3>
            <p>Cân nặng: ${pig.weight}kg</p>
            <p>Trạng thái: ${status}</p>
        `;
        pigList.appendChild(pigElement);
    });
}

function closeDashboard() {
    document.getElementById('dashboard').style.display = 'none';
    fetch('https://pig-farming/closeDashboard', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}
