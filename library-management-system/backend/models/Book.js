const mongoose = require('mongoose');

// Define Book Schema
const bookSchema = new mongoose.Schema(
  {
    // Required Fields
    title: {
      type: String,
      required: [true, 'Please provide a book title'],
      trim: true,
      minlength: [2, 'Title must be at least 2 characters long'],
      maxlength: [200, 'Title cannot exceed 200 characters'],
      index: true, // Index for faster searches
    },
    
    author: {
      type: String,
      required: [true, 'Please provide an author name'],
      trim: true,
      minlength: [2, 'Author name must be at least 2 characters long'],
      maxlength: [100, 'Author name cannot exceed 100 characters'],
      index: true,
    },
    
    isbn: {
      type: String,
      required: [true, 'Please provide an ISBN number'],
      trim: true,
      unique: [true, 'ISBN must be unique'],
      match: [/^[0-9-]+$/, 'Please provide a valid ISBN number'],
    },
    
    publishedYear: {
      type: Number,
      required: [true, 'Please provide a published year'],
      min: [1000, 'Published year must be a valid year'],
      max: [new Date().getFullYear() + 1, 'Published year cannot be in the future'],
    },
    
    // Optional Fields
    category: {
      type: String,
      trim: true,
      enum: {
        values: ['Fiction', 'Non-Fiction', 'Science', 'History', 'Biography', 'Technology', 'Self-Help', 'Mystery', 'Romance', 'Other'],
        message: 'Please select a valid category',
      },
      default: 'Other',
      index: true,
    },
    
    description: {
      type: String,
      trim: true,
      maxlength: [1000, 'Description cannot exceed 1000 characters'],
    },
    
    totalCopies: {
      type: Number,
      default: 1,
      min: [0, 'Total copies cannot be negative'],
      validate: {
        validator: function(value) {
          return value >= 0 && Number.isInteger(value);
        },
        message: 'Total copies must be a non-negative integer',
      },
    },
    
    availableCopies: {
      type: Number,
      default: function() {
        return this.totalCopies;
      },
      min: [0, 'Available copies cannot be negative'],
      validate: {
        validator: function(value) {
          return value <= this.totalCopies;
        },
        message: 'Available copies cannot exceed total copies',
      },
    },
    
    // Metadata
    createdAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
    
    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Indexes for optimized queries
bookSchema.index({ title: 'text', author: 'text', description: 'text' }); // Text search index

// Pre-save middleware
bookSchema.pre('save', function(next) {
  if (!this.isNew && this.isModified('totalCopies')) {
    if (this.availableCopies > this.totalCopies) {
      this.availableCopies = this.totalCopies;
    }
  }
  next();
});

// Virtual for book status
bookSchema.virtual('isAvailable').get(function() {
  return this.availableCopies > 0;
});

// Virtual for availability percentage
bookSchema.virtual('availabilityPercentage').get(function() {
  if (this.totalCopies === 0) return 0;
  return Math.round((this.availableCopies / this.totalCopies) * 100);
});

// Instance method to borrow a copy
bookSchema.methods.borrowCopy = function() {
  if (this.availableCopies > 0) {
    this.availableCopies -= 1;
    return true;
  }
  return false;
};

// Instance method to return a copy
bookSchema.methods.returnCopy = function() {
  if (this.availableCopies < this.totalCopies) {
    this.availableCopies += 1;
    return true;
  }
  return false;
};

// Create and export Book model
const Book = mongoose.model('Book', bookSchema);

module.exports = Book;
