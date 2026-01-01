import React, { useState } from 'react';

function BookForm({ onAddBook }) {
  const [formData, setFormData] = useState({
    title: '',
    author: '',
    isbn: '',
    publishedYear: '',
    totalCopies: 1,
  });

  const [errors, setErrors] = useState({});

  // Handle input change
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
    // Clear error for this field when user starts typing
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: '',
      }));
    }
  };

  // Validate form
  const validateForm = () => {
    const newErrors = {};
    if (!formData.title.trim()) newErrors.title = 'Book title is required';
    if (!formData.author.trim()) newErrors.author = 'Author name is required';
    if (!formData.isbn.trim()) newErrors.isbn = 'ISBN number is required';
    if (!formData.publishedYear || formData.publishedYear < 1000) newErrors.publishedYear = 'Valid publish year is required';
    
    return newErrors;
  };

  // Handle form submission
  const handleSubmit = (e) => {
    e.preventDefault();
    
    const newErrors = validateForm();
    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    onAddBook(formData);

    // Reset form
    setFormData({
      title: '',
      author: '',
      isbn: '',
      publishedYear: '',
      totalCopies: 1,
    });
    setErrors({});
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {/* Book Title */}
      <div>
        <label className="block text-sm font-semibold text-gray-700 mb-2">
          Book Title *
        </label>
        <input
          type="text"
          name="title"
          value={formData.title}
          onChange={handleChange}
          placeholder="Enter book title"
          className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 transition ${
            errors.title ? 'border-red-500' : 'border-gray-300'
          }`}
        />
        {errors.title && <p className="text-red-500 text-sm mt-1">{errors.title}</p>}
      </div>

      {/* Author Name */}
      <div>
        <label className="block text-sm font-semibold text-gray-700 mb-2">
          Author Name *
        </label>
        <input
          type="text"
          name="author"
          value={formData.author}
          onChange={handleChange}
          placeholder="Enter author name"
          className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 transition ${
            errors.author ? 'border-red-500' : 'border-gray-300'
          }`}
        />
        {errors.author && <p className="text-red-500 text-sm mt-1">{errors.author}</p>}
      </div>

      {/* ISBN Number */}
      <div>
        <label className="block text-sm font-semibold text-gray-700 mb-2">
          ISBN Number *
        </label>
        <input
          type="text"
          name="isbn"
          value={formData.isbn}
          onChange={handleChange}
          placeholder="Enter ISBN"
          className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 transition ${
            errors.isbn ? 'border-red-500' : 'border-gray-300'
          }`}
        />
        {errors.isbn && <p className="text-red-500 text-sm mt-1">{errors.isbn}</p>}
      </div>

      {/* Publish Year */}
      <div>
        <label className="block text-sm font-semibold text-gray-700 mb-2">
          Publish Year *
        </label>
        <input
          type="number"
          name="publishedYear"
          value={formData.publishedYear}
          onChange={handleChange}
          placeholder="e.g., 2024"
          className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 transition ${
            errors.publishedYear ? 'border-red-500' : 'border-gray-300'
          }`}
        />
        {errors.publishedYear && <p className="text-red-500 text-sm mt-1">{errors.publishedYear}</p>}
      </div>

      {/* Total Copies */}
      <div>
        <label className="block text-sm font-semibold text-gray-700 mb-2">
          Total Copies
        </label>
        <input
          type="number"
          name="totalCopies"
          value={formData.totalCopies}
          onChange={handleChange}
          min="1"
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 transition"
        />
      </div>

      {/* Submit Button */}
      <button
        type="submit"
        className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white py-3 rounded-lg font-bold text-lg hover:shadow-lg hover:from-blue-700 hover:to-indigo-700 transition duration-300 transform hover:scale-105"
      >
        ➕ Add Book
      </button>
    </form>
  );
}

export default BookForm;
