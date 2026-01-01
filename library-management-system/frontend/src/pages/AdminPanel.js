import React, { useEffect, useState } from 'react';
import { getAllBooks, addBook, updateBook, deleteBook } from '../api';
import '../styles/Admin.css';

function AdminPanel() {
  const [books, setBooks] = useState([]);
  const [formData, setFormData] = useState({
    title: '', author: '', isbn: '', category: '', publisher: '',
    publishedYear: '', totalCopies: '', description: '', language: '', pages: ''
  });
  const [editingId, setEditingId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');

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

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingId) {
        await updateBook(editingId, formData);
        setMessage('Book updated successfully');
        setEditingId(null);
      } else {
        await addBook(formData);
        setMessage('Book added successfully');
      }
      setFormData({
        title: '', author: '', isbn: '', category: '', publisher: '',
        publishedYear: '', totalCopies: '', description: '', language: '', pages: ''
      });
      fetchBooks();
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      setMessage('Error saving book');
    }
  };

  const handleEdit = (book) => {
    setFormData(book);
    setEditingId(book._id);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this book?')) {
      try {
        await deleteBook(id);
        setMessage('Book deleted successfully');
        fetchBooks();
        setTimeout(() => setMessage(''), 3000);
      } catch (error) {
        setMessage('Error deleting book');
      }
    }
  };

  return (
    <div className="admin-container">
      <h2>Admin Panel - Manage Books</h2>
      {message && <div className="message">{message}</div>}

      <form onSubmit={handleSubmit} className="book-form">
        <input type="text" name="title" placeholder="Title" value={formData.title} onChange={handleChange} required />
        <input type="text" name="author" placeholder="Author" value={formData.author} onChange={handleChange} required />
        <input type="text" name="isbn" placeholder="ISBN" value={formData.isbn} onChange={handleChange} />
        <input type="text" name="category" placeholder="Category" value={formData.category} onChange={handleChange} required />
        <input type="text" name="publisher" placeholder="Publisher" value={formData.publisher} onChange={handleChange} />
        <input type="number" name="publishedYear" placeholder="Published Year" value={formData.publishedYear} onChange={handleChange} />
        <input type="number" name="totalCopies" placeholder="Total Copies" value={formData.totalCopies} onChange={handleChange} required />
        <textarea name="description" placeholder="Description" value={formData.description} onChange={handleChange}></textarea>
        <input type="text" name="language" placeholder="Language" value={formData.language} onChange={handleChange} />
        <input type="number" name="pages" placeholder="Pages" value={formData.pages} onChange={handleChange} />
        <button type="submit">{editingId ? 'Update Book' : 'Add Book'}</button>
        {editingId && <button type="button" onClick={() => {
          setEditingId(null);
          setFormData({ title: '', author: '', isbn: '', category: '', publisher: '', publishedYear: '', totalCopies: '', description: '', language: '', pages: '' });
        }}>Cancel</button>}
      </form>

      {loading ? (
        <div className="loading">Loading books...</div>
      ) : (
        <table className="books-table">
          <thead>
            <tr>
              <th>Title</th>
              <th>Author</th>
              <th>Category</th>
              <th>Total</th>
              <th>Available</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {books.map(book => (
              <tr key={book._id}>
                <td>{book.title}</td>
                <td>{book.author}</td>
                <td>{book.category}</td>
                <td>{book.totalCopies}</td>
                <td>{book.availableCopies}</td>
                <td>
                  <button onClick={() => handleEdit(book)} className="edit-btn">Edit</button>
                  <button onClick={() => handleDelete(book._id)} className="delete-btn">Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

export default AdminPanel;
