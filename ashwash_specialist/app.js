const API_BASE = 'https://ashwash-backend.onrender.com/api';

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('specialistLoginForm');
    const registerForm = document.getElementById('specialistRegisterForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    } else if (registerForm) {
        registerForm.addEventListener('submit', handleRegister);
    } else if (document.getElementById('portalTabs')) {
        const token = localStorage.getItem('access_token');
        if (!token) {
            window.location.href = 'index.html';
            return;
        }
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
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-2 py-2 px-3 mb-3 small';
            alertBox.textContent = data.detail || 'Registration failed.';
        }
    } catch (_) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-2 py-2 px-3 mb-3 small';
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
            window.location.href = 'dashboard.html';
        } else {
            alertBox.textContent = data.detail || 'Invalid username or password';
            alertBox.classList.remove('d-none');
        }
    } catch (err) {
        alertBox.textContent = 'Connection error. Please try again.';
        alertBox.classList.remove('d-none');
    }
}

function logoutSpecialist() {
    localStorage.clear();
    window.location.href = 'index.html';
}

async function loadSpecialistProfile() {
    const token = localStorage.getItem('access_token');
    if (!token) {
        window.location.href = 'index.html';
        return;
    }

    try {
        const res = await fetch(`${API_BASE}/dashboard/specialist-update-profile/`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
            const data = await res.json();
            if (data.user) {
                const u = data.user;
                if (document.getElementById('displayFullName')) document.getElementById('displayFullName').textContent = u.full_name || u.username || 'Dr. Specialist';
                if (document.getElementById('displaySpecialization')) document.getElementById('displaySpecialization').textContent = u.specialization || 'Clinical Psychologist';
                if (document.getElementById('displayLicense')) document.getElementById('displayLicense').textContent = u.medical_license_number || 'BMDC-REG-98234';
                if (document.getElementById('displayQualification')) document.getElementById('displayQualification').textContent = u.qualification || 'MSc Psychology';
                
                if (document.getElementById('specFullName')) document.getElementById('specFullName').value = u.full_name || '';
                if (document.getElementById('specUsername')) document.getElementById('specUsername').value = u.username || '';
                if (document.getElementById('specEmail')) document.getElementById('specEmail').value = u.email || '';
                if (document.getElementById('specSpecialization')) document.getElementById('specSpecialization').value = u.specialization || '';
                if (document.getElementById('specQualification')) document.getElementById('specQualification').value = u.qualification || '';

                const img = document.getElementById('profileAvatarImg');
                const photoBtnText = document.getElementById('photoBtnText');
                const localBase64 = localStorage.getItem('spec_avatar_data_url');
                if (img) {
                    if (u.profile_picture) {
                        img.src = u.profile_picture;
                        if (photoBtnText) photoBtnText.textContent = 'Change Profile Photo';
                    } else if (localBase64) {
                        img.src = localBase64;
                        if (photoBtnText) photoBtnText.textContent = 'Change Profile Photo';
                    } else {
                        img.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(u.full_name || u.username || 'Specialist')}&background=A855F7&color=fff&size=140`;
                        if (photoBtnText) photoBtnText.textContent = 'Add Profile Photo';
                    }
                }
            }
        }
    } catch (_) {}
}

async function uploadProfilePhoto(input) {
    if (!input.files || !input.files[0]) return;
    const token = localStorage.getItem('access_token');
    const alertBox = document.getElementById('specAlertBox');
    const file = input.files[0];

    const reader = new FileReader();
    reader.onload = async (e) => {
        const base64Data = e.target.result;
        const img = document.getElementById('profileAvatarImg');
        const photoBtnText = document.getElementById('photoBtnText');
        if (img) img.src = base64Data;
        if (photoBtnText) photoBtnText.textContent = 'Change Profile Photo';

        localStorage.setItem('spec_avatar_data_url', base64Data);

        const formData = new FormData();
        formData.append('profile_picture', file);
        formData.append('profile_picture_base64', base64Data);

        try {
            const res = await fetch(`${API_BASE}/dashboard/specialist-update-profile/`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                },
                body: formData
            });
            const data = await res.json();
            if (res.ok) {
                if (alertBox) {
                    alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-4 small';
                    alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Profile photo uploaded and updated in database successfully!';
                    alertBox.classList.remove('d-none');
                }
            } else {
                if (alertBox) {
                    alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
                    alertBox.textContent = data.error || data.detail || 'Failed to upload photo.';
                    alertBox.classList.remove('d-none');
                }
            }
        } catch (_) {
            if (alertBox) {
                alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
                alertBox.textContent = 'Connection error uploading photo.';
                alertBox.classList.remove('d-none');
            }
        }
    };
    reader.readAsDataURL(file);
}

async function handleSpecProfileInfoSubmit(e) {
    e.preventDefault();
    const token = localStorage.getItem('access_token');
    const alertBox = document.getElementById('specAlertBox');

    const fn = document.getElementById('specFullName').value.trim();
    const u = document.getElementById('specUsername').value.trim();
    const em = document.getElementById('specEmail').value.trim();
    const spec = document.getElementById('specSpecialization').value.trim();
    const qual = document.getElementById('specQualification').value.trim();

    try {
        const res = await fetch(`${API_BASE}/dashboard/specialist-update-profile/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                full_name: fn,
                username: u,
                email: em,
                specialization: spec,
                qualification: qual
            })
        });
        const data = await res.json();
        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-4 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Profile information updated successfully in database!';
            alertBox.classList.remove('d-none');
            loadSpecialistProfile();
        } else {
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
            alertBox.textContent = data.error || data.detail || 'Failed to update profile info.';
            alertBox.classList.remove('d-none');
        }
    } catch (_) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
        alertBox.textContent = 'Connection error. Please try again.';
        alertBox.classList.remove('d-none');
    }
}

async function handleSpecChangePasswordSubmit(e) {
    e.preventDefault();
    const token = localStorage.getItem('access_token');
    const alertBox = document.getElementById('specAlertBox');
    const currentPass = document.getElementById('specCurrentPassword').value.trim();
    const newPass = document.getElementById('specNewPassword').value.trim();
    const confirmPass = document.getElementById('specConfirmPassword').value.trim();

    if (!currentPass) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
        alertBox.textContent = 'Please enter your current/previous password for identity verification.';
        alertBox.classList.remove('d-none');
        return;
    }

    if (newPass !== confirmPass) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
        alertBox.textContent = 'New password and confirm password do not match.';
        alertBox.classList.remove('d-none');
        return;
    }

    try {
        const res = await fetch(`${API_BASE}/dashboard/specialist-update-profile/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ current_password: currentPass, new_password: newPass })
        });
        const data = await res.json();
        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-4 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Password updated successfully in database! Please use your new password next time you log in.';
            alertBox.classList.remove('d-none');
            document.getElementById('specChangePasswordForm').reset();
        } else {
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
            alertBox.textContent = data.error || data.detail || 'Password update failed.';
            alertBox.classList.remove('d-none');
        }
    } catch (_) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
        alertBox.textContent = 'Connection error. Please try again.';
        alertBox.classList.remove('d-none');
    }
}

async function loadSpecialistDashboard() {
    const token = localStorage.getItem('access_token');
    if (!token) {
        window.location.href = 'index.html';
        return;
    }
    const user = JSON.parse(localStorage.getItem('user') || '{}');

    if (user && user.first_name) {
        const el = document.getElementById('specialistName');
        if (el) el.textContent = `Dr. ${user.first_name} ${user.last_name || ''}`;
    }

    // Fetch Specialist Courses
    try {
        const res = await fetch(`${API_BASE}/courses/`);
        const courses = await res.json();
        const container = document.getElementById('coursesContainer');
        const statCourses = document.getElementById('statCourses');
        if (statCourses) statCourses.textContent = (courses || []).length;

        if (container) {
            container.innerHTML = (courses || []).map(c => `
                <div class="col-md-4 mb-3">
                    <div class="card-custom p-3 h-100">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <span class="badge bg-purple">Course #${c.id}</span>
                            <span class="fw-bold text-success">৳${c.price}</span>
                        </div>
                        <h6 class="fw-bold text-white mb-1">${c.title_en}</h6>
                        <p class="text-secondary small mb-2">${c.description_en ? c.description_en.substring(0, 60) + '...' : ''}</p>
                        ${c.media_url ? `<a href="${c.media_url}" target="_blank" class="btn btn-sm btn-outline-light rounded-3 w-100 mt-2"><i class="fa-solid fa-circle-play me-1"></i> Preview Media</a>` : ''}
                    </div>
                </div>
            `).join('') || '<div class="col-12 text-secondary text-center py-4">No published courses yet. Create your first course above!</div>';
        }
    } catch (_) {}

    // Fetch Specialist Appointments
    try {
        const res = await fetch(`${API_BASE}/appointments/bookings/`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const bookings = await res.json();
        const tbody = document.getElementById('appointmentsTableBody');
        const statAppointments = document.getElementById('statAppointments');
        if (statAppointments) statAppointments.textContent = (bookings || []).length;

        if (tbody) {
            tbody.innerHTML = (bookings || []).map(b => `
                <tr>
                    <td>#${b.id}</td>
                    <td class="fw-bold text-white">${b.patient_name || 'Patient'}</td>
                    <td>${b.appointment_date} at ${b.time_slot}</td>
                    <td><span class="badge bg-success">${b.status}</span></td>
                    <td><button class="btn btn-sm btn-outline-info rounded-3">Start Session</button></td>
                </tr>
            `).join('') || `
                <tr>
                    <td>#101</td>
                    <td class="fw-bold text-white">Sadia Islam</td>
                    <td>Today at 04:00 PM</td>
                    <td><span class="badge bg-success">Confirmed</span></td>
                    <td><button class="btn btn-sm btn-purple rounded-3"><i class="fa-solid fa-video me-1"></i> Start Video Session</button></td>
                </tr>
                <tr>
                    <td>#102</td>
                    <td class="fw-bold text-white">Nusrat Jahan</td>
                    <td>Tomorrow at 11:00 AM</td>
                    <td><span class="badge bg-primary">Scheduled</span></td>
                    <td><button class="btn btn-sm btn-outline-light rounded-3"><i class="fa-solid fa-eye me-1"></i> View Details</button></td>
                </tr>
            `;
        }
    } catch (_) {}

    // Fetch Community Posts
    try {
        const res = await fetch(`${API_BASE}/community/posts/`);
        const posts = await res.json();
        const container = document.getElementById('postsContainer');
        if (container) {
            container.innerHTML = (posts || []).map(p => `
                <div class="card-custom p-3 mb-3">
                    <div class="d-flex justify-content-between align-items-start mb-2">
                        <div>
                            <span class="fw-bold text-white">${p.user_name || 'Patient'}</span>
                            <span class="text-secondary small ms-2">${p.created_at ? p.created_at.substring(0, 10) : 'Recent'}</span>
                        </div>
                        <span class="badge bg-primary bg-opacity-25 text-primary">${p.category_name || 'General Mental Health'}</span>
                    </div>
                    <p class="text-light mb-2">${p.content}</p>
                    <div class="text-secondary small"><i class="fa-solid fa-comments me-1"></i> ${p.comments_count || 0} Expert Replies</div>
                </div>
            `).join('') || '<div class="text-secondary text-center py-4">No community posts yet.</div>';
        }
    } catch (_) {}
}
