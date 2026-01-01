import React, { useEffect, useState } from 'react';
import { getUserLoans, returnBook } from '../api';
import '../styles/MyLoans.css';

function MyLoans() {
  const [loans, setLoans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');
  const user = JSON.parse(localStorage.getItem('user') || '{}');

  useEffect(() => {
    fetchLoans();
  }, []);

  const fetchLoans = async () => {
    try {
      const data = await getUserLoans(user.id);
      setLoans(data);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching loans:', error);
      setLoading(false);
    }
  };

  const handleReturn = async (loanId) => {
    try {
      const response = await returnBook(loanId);
      if (response.message) {
        setMessage(response.message);
        setTimeout(() => setMessage(''), 3000);
        fetchLoans();
      }
    } catch (error) {
      setMessage('Error returning book');
    }
  };

  return (
    <div className="loans-container">
      <h2>My Borrowed Books</h2>
      {message && <div className="message">{message}</div>}

      {loading ? (
        <div className="loading">Loading loans...</div>
      ) : loans.length === 0 ? (
        <p>You haven't borrowed any books yet.</p>
      ) : (
        <table className="loans-table">
          <thead>
            <tr>
              <th>Book Title</th>
              <th>Author</th>
              <th>Borrow Date</th>
              <th>Due Date</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {loans.map(loan => (
              <tr key={loan._id}>
                <td>{loan.bookId?.title}</td>
                <td>{loan.bookId?.author}</td>
                <td>{new Date(loan.borrowDate).toLocaleDateString()}</td>
                <td>{new Date(loan.dueDate).toLocaleDateString()}</td>
                <td>
                  <span className={`status ${loan.status}`}>{loan.status}</span>
                </td>
                <td>
                  {loan.status === 'active' && (
                    <button onClick={() => handleReturn(loan._id)}>Return</button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

export default MyLoans;
