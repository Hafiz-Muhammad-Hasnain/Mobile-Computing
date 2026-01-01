const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:5000/api';

export const getAuthToken = () => localStorage.getItem('token');

export const setAuthToken = (token) => localStorage.setItem('token', token);

export const removeAuthToken = () => localStorage.removeItem('token');

export const getConfig = () => {
  const token = getAuthToken();
  return {
    headers: {
      Authorization: token ? `Bearer ${token}` : ''
    }
  };
};

// Auth API
export const register = async (name, email, password) => {
  const response = await fetch(`${API_BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, email, password })
  });
  return response.json();
};

export const login = async (email, password) => {
  const response = await fetch(`${API_BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  return response.json();
};

// Book API
export const getAllBooks = async () => {
  const response = await fetch(`${API_BASE_URL}/books`);
  return response.json();
};

export const getBook = async (id) => {
  const response = await fetch(`${API_BASE_URL}/books/${id}`);
  return response.json();
};

export const addBook = async (bookData) => {
  const response = await fetch(`${API_BASE_URL}/books`, {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      ...getConfig().headers
    },
    body: JSON.stringify(bookData)
  });
  return response.json();
};

export const updateBook = async (id, bookData) => {
  const response = await fetch(`${API_BASE_URL}/books/${id}`, {
    method: 'PUT',
    headers: { 
      'Content-Type': 'application/json',
      ...getConfig().headers
    },
    body: JSON.stringify(bookData)
  });
  return response.json();
};

export const deleteBook = async (id) => {
  const response = await fetch(`${API_BASE_URL}/books/${id}`, {
    method: 'DELETE',
    headers: getConfig().headers
  });
  return response.json();
};

// Loan API
export const borrowBook = async (bookId) => {
  const response = await fetch(`${API_BASE_URL}/loans/borrow`, {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      ...getConfig().headers
    },
    body: JSON.stringify({ bookId })
  });
  return response.json();
};

export const returnBook = async (loanId) => {
  const response = await fetch(`${API_BASE_URL}/loans/return/${loanId}`, {
    method: 'POST',
    headers: getConfig().headers
  });
  return response.json();
};

export const getUserLoans = async (userId) => {
  const response = await fetch(`${API_BASE_URL}/loans/user/${userId}`, {
    headers: getConfig().headers
  });
  return response.json();
};

export const getAllLoans = async () => {
  const response = await fetch(`${API_BASE_URL}/loans`, {
    headers: getConfig().headers
  });
  return response.json();
};

// User API
export const getUserProfile = async (userId) => {
  const response = await fetch(`${API_BASE_URL}/users/profile/${userId}`, {
    headers: getConfig().headers
  });
  return response.json();
};

export const updateUserProfile = async (userId, userData) => {
  const response = await fetch(`${API_BASE_URL}/users/${userId}`, {
    method: 'PUT',
    headers: { 
      'Content-Type': 'application/json',
      ...getConfig().headers
    },
    body: JSON.stringify(userData)
  });
  return response.json();
};
