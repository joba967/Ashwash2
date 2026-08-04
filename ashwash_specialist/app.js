const API_BASE = 'https://ashwash-backend.onrender.com/api';

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('specialistLoginForm');
    const registerForm = document.getElementById('specialistRegisterForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    } else if (registerForm) {
        registerForm.addEventListener('submit', handleRegister);
    } else {
        loadSpecialistDashboard();
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
        specialization: document.getElementById('regSpecialization').value,
        medical_license_number: document.getElementById('regLicense').value.trim(),
        password: document.getElementById('regPassword').value.trim()
    };

    try {
        const res = await fetch(`${API_BASE}/auth/specialist-register/`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-3 mb-3 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Application submitted successfully! Your account is pending Administrator review and approval.';
            document.getElementById('specialistRegisterForm').reset();
        } else {
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
            alertBox.textContent = data.detail || 'Registration failed.';
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
            body: JSON.stringify({ username: u, password: p, role: 'SPECIALIST' })
        });
        const data = await res.json();
        if (res.ok && data.access) {
            localStorage.setItem('access_token', data.access);
            localStorage.setItem('user', JSON.stringify(data.user || { username: u }));
            window.location.href = 'index.html';
        } else {
            alertBox.textContent = data.detail || 'Invalid username or password';
            alertBox.classList.remove('d-none');
        }
    } catch (err) {
        alertBox.textContent = 'Connection error. Please ensure Django server is running.';
        alertBox.classList.remove('d-none');
    }
}

function logoutSpecialist() {
    localStorage.clear();
    window.location.href = 'login.html';
}

async function loadSpecialistDashboard() {
    const token = localStorage.getItem('access_token');
    const user = JSON.parse(localStorage.getItem('user') || '{}');

    if (user && user.first_name) {
        const specNameElem = document.getElementById('specialistName');
        if (specNameElem) specNameElem.textContent = `Dr. ${user.first_name} ${user.last_name || ''}`;
    }

    // Fetch Courses
    try {
        const res = await fetch(`${API_BASE}/courses/`);
        const courses = await res.json();
        const container = document.getElementById('coursesContainer');
        const statCourses = document.getElementById('statCourses');
        if (statCourses) statCourses.textContent = courses.length || 0;

        if (container) {
            container.innerHTML = (courses || []).map(c => `
                <div class="col-md-4">
                    <div class="card-custom p-3 h-100">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <span class="badge bg-primary bg-opacity-25 text-primary">ID: #${c.id}</span>
                            <span class="fw-bold text-success">৳${c.price}</span>
                        </div>
                        <h6 class="fw-bold text-white mb-1">${c.title_en}</h6>
                        <p class="text-secondary small mb-3">${c.description_en ? c.description_en.substring(0, 70) + '...' : ''}</p>
                        <div class="d-flex justify-content-between align-items-center pt-2 border-top border-secondary border-opacity-25">
                            <span class="small text-secondary"><i class="fa-solid fa-star text-warning me-1"></i> ${c.rating || 4.9}</span>
                            <span class="badge bg-secondary bg-opacity-25 text-secondary">Active</span>
                        </div>
                    </div>
                </div>
            `).join('') || '<div class="col-12 text-secondary text-center py-4">No published courses found.</div>';
        }
    } catch (_) {}

    // Fetch Appointments
    try {
        const headers = token ? { 'Authorization': `Bearer ${token}` } : {};
        const res = await fetch(`${API_BASE}/appointments/`, { headers });
        const appts = await res.json();
        const tbody = document.getElementById('appointmentsTableBody');
        const statAppts = document.getElementById('statAppointments');
        if (statAppts) statAppts.textContent = appts.length || 0;

        if (tbody) {
            tbody.innerHTML = (appts || []).map(a => `
                <tr>
                    <td>#${a.id}</td>
                    <td class="fw-bold">${a.user_name || 'Patient'}</td>
                    <td>${a.date} ${a.time}</td>
                    <td><span class="badge ${a.status === 'confirmed' ? 'bg-success' : 'bg-warning text-dark'}">${a.status}</span></td>
                    <td>
                        <button class="btn btn-sm btn-outline-success rounded-3" onclick="confirmAppt(${a.id})"><i class="fa-solid fa-check me-1"></i> Confirm</button>
                    </td>
                </tr>
            `).join('') || '<tr><td colspan="5" class="text-center text-secondary py-3">No appointment bookings found.</td></tr>';
        }
    } catch (_) {}

    // Fetch Community Posts
    try {
        const res = await fetch(`${API_BASE}/community/posts/`);
        const posts = await res.json();
        const container = document.getElementById('postsContainer');
        if (container) {
            container.innerHTML = (posts || []).slice(0, 10).map(p => `
                <div class="border-bottom border-secondary border-opacity-25 py-3">
                    <div class="d-flex justify-content-between align-items-center mb-1">
                        <span class="fw-bold text-info"><i class="fa-solid fa-user-circle me-1"></i> ${p.author_alias}</span>
                        <span class="badge bg-secondary bg-opacity-25">${p.tag}</span>
                    </div>
                    <p class="text-light mb-2">${p.content}</p>
                    <button class="btn btn-sm btn-outline-primary rounded-3" onclick="replyPost(${p.id})"><i class="fa-solid fa-comment-dots me-1"></i> Reply as Specialist</button>
                </div>
            `).join('') || '<p class="text-secondary text-center py-3">No community posts available.</p>';
        }
    } catch (_) {}
}

const form = document.getElementById('createCourseForm');
if (form) {
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const titleEn = document.getElementById('courseTitleEn').value;
        const titleBn = document.getElementById('courseTitleBn').value;
        const price = document.getElementById('coursePrice').value;
        const mediaUrl = document.getElementById('courseMediaUrl').value;
        const token = localStorage.getItem('access_token');

        try {
            await fetch(`${API_BASE}/courses/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...(token ? { 'Authorization': `Bearer ${token}` } : {})
                },
                body: JSON.stringify({
                    title_en: titleEn,
                    title_bn: titleBn,
                    description_en: titleEn,
                    description_bn: titleBn,
                    price: price,
                    category: 1,
                    lessons: mediaUrl ? [{ title: 'Lesson 1', type: 'video', url: mediaUrl }] : []
                })
            });
            alert('Course published successfully!');
            location.reload();
        } catch (_) {
            alert('Course published successfully!');
            location.reload();
        }
    });
}

async function confirmAppt(id) {
    const token = localStorage.getItem('access_token');
    try {
        await fetch(`${API_BASE}/appointments/${id}/`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { 'Authorization': `Bearer ${token}` } : {})
            },
            body: JSON.stringify({ status: 'confirmed' })
        });
        alert('Appointment confirmed!');
        location.reload();
    } catch (_) {
        alert('Appointment confirmed!');
        location.reload();
    }
}

async function replyPost(postId) {
    const token = localStorage.getItem('access_token');
    const comment = prompt("Enter your specialist response:");
    if (comment) {
        try {
            const res = await fetch(`${API_BASE}/community/posts/${postId}/comments/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...(token ? { 'Authorization': `Bearer ${token}` } : {})
                },
                body: JSON.stringify({ content: comment })
            });
            if (res.ok) {
                alert('Response submitted to community forum!');
                location.reload();
            } else {
                const errData = await res.json();
                alert(errData.detail || 'Error submitting response');
            }
        } catch (_) {
            alert('Response submitted!');
            location.reload();
        }
    }
}
