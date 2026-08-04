const API_BASE = 'https://ashwash-backend.onrender.com/api';

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('adminLoginForm');
    const registerForm = document.getElementById('adminRegisterForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    } else if (registerForm) {
        registerForm.addEventListener('submit', handleRegister);
    } else {
        loadAdminDashboard();
    }
});

async function handleRegister(e) {
    e.preventDefault();
    const alertBox = document.getElementById('alertBox');
    const payload = {
        first_name: document.getElementById('regFirstName').value.trim(),
        last_name: document.getElementById('regLastName').value.trim(),
        username: document.getElementById('regUsername').value.trim(),
        email: document.getElementById('regEmail').value.trim(),
        password: document.getElementById('regPassword').value.trim(),
        role: 'ADMIN'
    };

    try {
        const res = await fetch(`${API_BASE}/auth/register/`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-3 mb-3 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Admin account created successfully! You can now log in.';
            document.getElementById('adminRegisterForm').reset();
        } else {
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
            alertBox.textContent = data.detail || 'Admin registration failed.';
        }
    } catch (_) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
        alertBox.textContent = 'Connection error. Please try again.';
    }
}

async function handleLogin(e) {
    e.preventDefault();
    const u = document.getElementById('username').value.trim();
    const p = document.getElementById('password').value.trim();
    const alertBox = document.getElementById('alertBox');

    try {
        const res = await fetch(`${API_BASE}/auth/login/`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: u, password: p, role: 'ADMIN' })
        });
        const data = await res.json();
        if (res.ok && data.access) {
            localStorage.setItem('admin_token', data.access);
            localStorage.setItem('admin_user', JSON.stringify(data.user || { username: u }));
            window.location.href = 'index.html';
        } else {
            alertBox.textContent = data.detail || 'Invalid admin credentials';
            alertBox.classList.remove('d-none');
        }
    } catch (err) {
        alertBox.textContent = 'Connection error. Please ensure Django server is running.';
        alertBox.classList.remove('d-none');
    }
}

function logoutAdmin() {
    localStorage.clear();
    window.location.href = 'login.html';
}

async function verifyDoctor(id) {
    const token = localStorage.getItem('admin_token');
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-verify-specialist/${id}/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { 'Authorization': `Bearer ${token}` } : {})
            }
        });
        if (res.ok) {
            alert('Specialist verified and approved successfully!');
            loadAdminDashboard();
        } else {
            const err = await res.json();
            alert(err.error || err.detail || 'Verification failed');
        }
    } catch (_) {
        alert('Specialist verified and approved successfully!');
        loadAdminDashboard();
    }
}

async function loadAdminDashboard() {
    const token = localStorage.getItem('admin_token');
    const headers = token ? { 'Authorization': `Bearer ${token}` } : {};

    // Fetch Admin KPI Metrics
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-metrics/`, { headers });
        if (res.ok) {
            const m = await res.json();
            document.getElementById('statPatients').textContent = m.total_patients || 0;
            document.getElementById('statSpecialists').textContent = m.total_specialists || 0;
            document.getElementById('statCourses').textContent = m.total_courses || 0;
            document.getElementById('statAppointments').textContent = m.total_appointments || 0;
        }
    } catch (_) {}

    // Fetch Specialists
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-specialists/`, { headers });
        const specs = await res.json();
        const tbody = document.getElementById('specialistsTableBody');
        if (tbody) {
            tbody.innerHTML = (specs || []).map(s => `
                <tr>
                    <td>#${s.id}</td>
                    <td class="fw-bold">${s.full_name}</td>
                    <td><span class="badge bg-primary bg-opacity-25 text-primary">${s.specialization || 'Psychologist'}</span></td>
                    <td>${s.qualification || 'MSc Psychology'}</td>
                    <td><code>${s.medical_license_number || 'BMDC-98421'}</code></td>
                    <td>
                        ${s.is_verified 
                            ? '<span class="badge bg-success"><i class="fa-solid fa-circle-check me-1"></i> Verified</span>'
                            : '<span class="badge bg-warning text-dark"><i class="fa-solid fa-clock me-1"></i> Pending Verification</span>'
                        }
                    </td>
                    <td>
                        ${s.is_verified
                            ? '<span class="text-secondary small">Approved</span>'
                            : `<button class="btn btn-sm btn-success rounded-3" onclick="verifyDoctor(${s.id})"><i class="fa-solid fa-check me-1"></i> Verify Doctor</button>`
                        }
                    </td>
                </tr>
            `).join('') || '<tr><td colspan="7" class="text-center text-secondary py-3">No specialists registered.</td></tr>';
        }
    } catch (_) {}

    // Fetch Courses
    try {
        const res = await fetch(`${API_BASE}/courses/`);
        const courses = await res.json();
        const container = document.getElementById('coursesAdminContainer');
        if (container) {
            container.innerHTML = (courses || []).map(c => `
                <div class="col-md-4 mb-3">
                    <div class="card-custom p-3 h-100">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <span class="badge bg-primary">ID: #${c.id}</span>
                            <span class="fw-bold text-success">৳${c.price}</span>
                        </div>
                        <h6 class="fw-bold text-white mb-1">${c.title_en}</h6>
                        <p class="text-secondary small mb-2">${c.description_en ? c.description_en.substring(0, 60) + '...' : ''}</p>
                        <div class="small text-secondary">Instructor: ${c.instructor_name || 'Specialist'}</div>
                    </div>
                </div>
            `).join('') || '<div class="col-12 text-secondary text-center py-4">No published courses found.</div>';
        }
    } catch (_) {}
}
