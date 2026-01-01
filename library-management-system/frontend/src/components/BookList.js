import React from 'react';
import BookCard from './BookCard';

function BookList({ books, onDeleteBook }) {
  // Display books in a responsive grid
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-1 gap-6">
      {books.map(book => (
        <BookCard
          key={book._id}
          book={book}
          onDelete={onDeleteBook}
        />
      ))}
    </div>
  );
}

export default BookList;
