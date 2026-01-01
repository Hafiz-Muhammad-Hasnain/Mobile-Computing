import React, { useState, useEffect } from 'react';
import BookForm from './components/BookForm';
import BookList from './components/BookList';
import './App.css';

function App() {
  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  // Fetch books from backend on component mount
  useEffect(() => {
    fetchBooks();
  }, []);

  const fetchBooks = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await fetch('/api/books');
      if (!response.ok) {
        throw new Error('Failed to fetch books');
      }
      const result = await response.json();
      // Handle both array and object responses
      const booksData = Array.isArray(result) ? result : result.data || [];
      setBooks(booksData);
    } catch (err) {
      setError('Error fetching books: ' + err.message);
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // Handle adding a new book
  const handleAddBook = async (bookData) => {
    try {
      const response = await fetch('/api/books', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(bookData),
      });

      if (!response.ok) {
        throw new Error('Failed to add book');
      }

      const result = await response.json();
      const newBook = result.book || result.data || result;
      setBooks([...books, newBook]);
      setSuccessMessage('Book added successfully!');
      setTimeout(() => setSuccessMessage(''), 3000);
    } catch (err) {
      setError('Error adding book: ' + err.message);
      console.error(err);
    }
  };

  // Handle deleting a book
  const handleDeleteBook = async (bookId) => {
    if (window.confirm('Are you sure you want to delete this book?')) {
      try {
        const response = await fetch(`/api/books/${bookId}`, {
          method: 'DELETE',
        });

        if (!response.ok) {
          throw new Error('Failed to delete book');
        }

        setBooks(books.filter(book => book._id !== bookId));
        setSuccessMessage('Book deleted successfully!');
        setTimeout(() => setSuccessMessage(''), 3000);
      } catch (err) {
        setError('Error deleting book: ' + err.message);
        console.error(err);
      }
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Header */}
      <header className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-lg">
        <div className="container mx-auto px-4 py-8">
          <h1 className="text-4xl font-bold">📚 Library Management System</h1>
          <p className="text-blue-100 mt-2">Manage your book collection with ease</p>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {/* Alert Messages */}
        {error && (
          <div className="mb-6 p-4 bg-red-100 border border-red-400 text-red-700 rounded-lg animate-pulse">
            {error}
          </div>
        )}
        {successMessage && (
          <div className="mb-6 p-4 bg-green-100 border border-green-400 text-green-700 rounded-lg animate-pulse">
            {successMessage}
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Form Section */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-lg shadow-lg p-6 sticky top-8">
              <h2 className="text-2xl font-bold text-gray-800 mb-6">Add New Book</h2>
              <BookForm onAddBook={handleAddBook} />
            </div>
          </div>

          {/* Books List Section */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow-lg p-6">
              <h2 className="text-2xl font-bold text-gray-800 mb-6">
                Books Library ({books.length})
              </h2>

              {loading ? (
                <div className="flex items-center justify-center py-12">
                  <div className="text-center">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto mb-4"></div>
                    <p className="text-gray-600">Loading books...</p>
                  </div>
                </div>
              ) : books.length === 0 ? (
                <div className="text-center py-12">
                  <p className="text-gray-500 text-lg">No books added yet. Start by adding a new book!</p>
                </div>
              ) : (
                <BookList books={books} onDeleteBook={handleDeleteBook} />
              )}
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-800 text-white mt-12">
        <div className="container mx-auto px-4 py-6 text-center">
          <p>&copy; 2024 Library Management System. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}

export default App;

















