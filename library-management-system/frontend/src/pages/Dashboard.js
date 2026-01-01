import React, { useEffect, useState } from 'react';
import { getAllBooks, borrowBook } from '../api';
import '../styles/Dashboard.css';

function Dashboard() {
  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [message, setMessage] = useState('');
  const user = JSON.parse(localStorage.getItem('user') || '{}');

  useEffect(() => {
    fetchBooks();
  }, []);

  const fetchBooks = async () => {
    try {
      const data = await getAllBooks();
      setBooks(data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching books:', error);
      setLoading(false);
    }
  };

  const handleBorrow = async (bookId) => {
    try {
      const response = await borrowBook(bookId);
      if (response.message) {
        setMessage(response.message);
        setTimeout(() => setMessage(''), 3000);
        fetchBooks();
      }
    } catch (error) {
      setMessage('Error borrowing book');
    }
  };

  const filteredBooks = books.filter(book =>
    book.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    book.author.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="dashboard-container">
      <header className="dashboard-header">
        <h1>Library Management System</h1>
        <div className="user-info">
          <span>Welcome, {user.name}</span>
          <button onClick={() => {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            window.location.href = '/login';
          }}>Logout</button>
        </div>
      </header>

      {message && <div className="message">{message}</div>}

      <div className="search-bar">
        <input
          type="text"
          placeholder="Search by book title or author..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
      </div>

      {loading ? (
        <div className="loading">Loading books...</div>
      ) : (
        <div className="books-grid">
          {filteredBooks.map(book => (
            <div key={book._id} className="book-card">
              <h3>{book.title}</h3>
              <p><strong>Author:</strong> {book.author}</p>
              <p><strong>Category:</strong> {book.category}</p>
              <p><strong>Available:</strong> {book.availableCopies}/{book.totalCopies}</p>
              <p>{book.description}</p>
              <button
                onClick={() => handleBorrow(book._id)}
                disabled={book.availableCopies === 0}
                className={book.availableCopies === 0 ? 'disabled' : ''}
              >
                {book.availableCopies === 0 ? 'Not Available' : 'Borrow'}
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default Dashboard;
