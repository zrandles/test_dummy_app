import { Controller } from "@hotwired/stimulus"

/**
 * Advanced Table Filter Controller for Golden Deployment Template
 *
 * Features:
 * - 3-state column visibility (hidden → shown → featured)
 * - Dual-handle range sliders with percentile markers
 * - Filter mode (hide rows) vs Elimination mode (highlight failing cells)
 * - LocalStorage persistence
 * - Real-time row count display
 *
 * Adapted from bull_attributes app - the crown jewel of our filtering system.
 * This is production-tested code used for filtering 70+ columns of cattle data.
 */
export default class extends Controller {
  static targets = ["modal", "filterBar", "table", "tbody", "resultCount", "hiddenList", "shownList", "featuredList", "searchInput"]
  static values = {
    columns: Array,
    percentiles: Object
  }

  connect() {
    console.log('Filter controller connected!')
    this.searchTerm = ''
    this.loadExamples()
    this.loadPercentileValues()
    this.initializeColumns()  // Initialize columns first
    this.loadState()
    this.buildTable()
    this.renderModal()
    this.renderFilterBar()
    this.applyFilters()
  }

  /**
   * Load example data from embedded JSON script tag
   */
  loadExamples() {
    try {
      const dataScript = document.getElementById('examples-data')
      if (!dataScript) {
        console.error('❌ No examples-data script tag found')
        this.examples = []
        return
      }

      const jsonText = dataScript.textContent.trim()
      this.examples = JSON.parse(jsonText)
      console.log(`✅ Loaded ${this.examples.length} examples`)
    } catch (e) {
      console.error('❌ Failed to parse examples data:', e)
      this.examples = []
    }
  }

  /**
   * Load pre-calculated percentile values for slider markers
   */
  loadPercentileValues() {
    try {
      const dataScript = document.getElementById('percentile-values')
      if (!dataScript) {
        console.error('❌ No percentile-values script tag found')
        this.percentileValues = {}
        return
      }

      this.percentileValues = JSON.parse(dataScript.textContent.trim())
      console.log(`✅ Loaded percentile values for ${Object.keys(this.percentileValues).length} columns`)
    } catch (e) {
      console.error('❌ Failed to parse percentile values:', e)
      this.percentileValues = {}
    }
  }

  /**
   * Load saved filter state from localStorage
   */
  loadState() {
    const saved = localStorage.getItem('exampleFilterState')
    if (saved) {
      console.log('Loading saved state from localStorage')
      const state = JSON.parse(saved)
      this.hiddenColumns = state.hidden || []
      this.shownColumns = state.shown || []
      this.featuredColumns = state.featured || {}

      // Ensure all featured columns have a mode (default to 'filter')
      Object.keys(this.featuredColumns).forEach(key => {
        if (!this.featuredColumns[key].mode) {
          this.featuredColumns[key].mode = 'filter'
        }
      })
    } else {
      console.log('Using default state (no saved state)')
      // Default state: ALL columns shown, none hidden
      this.shownColumns = this.allColumns.map(col => col.key)
      this.hiddenColumns = []
      this.featuredColumns = {}
    }
    console.log(`State loaded: ${this.shownColumns.length} shown, ${this.hiddenColumns.length} hidden, ${Object.keys(this.featuredColumns).length} featured`)
  }

  /**
   * Save current filter state to localStorage
   */
  saveState() {
    const state = {
      hidden: this.hiddenColumns,
      shown: this.shownColumns,
      featured: this.featuredColumns
    }
    localStorage.setItem('exampleFilterState', JSON.stringify(state))
  }

  /**
   * Define all available columns
   * Customize this for your app's data structure
   */
  initializeColumns() {
    this.allColumns = [
      // Identifiers
      { key: 'name', name: 'Name', category: 'Identifiers', filterable: false },
      { key: 'category', name: 'Category', category: 'Identifiers', filterable: false },
      { key: 'status', name: 'Status', category: 'Identifiers', filterable: false },

      // Metrics
      { key: 'priority', name: 'Priority', category: 'Metrics', filterable: true },
      { key: 'score', name: 'Score', category: 'Metrics', filterable: true },
      { key: 'complexity', name: 'Complexity', category: 'Metrics', filterable: true },
      { key: 'speed', name: 'Speed', category: 'Metrics', filterable: true },
      { key: 'quality', name: 'Quality', category: 'Metrics', filterable: true },
      { key: 'average_metrics', name: 'Avg Metrics', category: 'Metrics', filterable: true }
    ]

    // Store original rows (will be replaced by buildTable)
    this.allRows = []
  }

  /**
   * Build table HTML from scratch with visible columns
   */
  buildTable() {
    // Get visible columns (shown + featured)
    const visibleColumns = this.allColumns.filter(c =>
      this.shownColumns.includes(c.key) || this.featuredColumns[c.key]
    )

    console.log(`Building table with ${visibleColumns.length} visible columns and ${this.examples.length} examples`)

    // Pre-calculate percentiles for all filterable columns for highlighting
    this.columnPercentiles = this.calculateAllPercentiles()

    // Build table headers
    const thead = this.tableTarget.querySelector('thead')
    thead.innerHTML = this.buildTableHeaders(visibleColumns)

    // Build table rows
    const tbody = this.tbodyTarget
    tbody.innerHTML = this.examples.map(example => this.buildTableRow(example, visibleColumns)).join('')

    // Store rows for filtering
    this.allRows = Array.from(tbody.querySelectorAll('tr'))
    console.log(`✅ Table built: ${this.allRows.length} rows`)
  }

  /**
   * Calculate percentiles for all filterable columns (for cell highlighting)
   */
  calculateAllPercentiles() {
    const percentiles = {}

    this.allColumns.filter(c => c.filterable).forEach(col => {
      const values = []

      this.examples.forEach(example => {
        const value = example[col.key]
        if (value !== null && value !== undefined && value !== '' && !isNaN(parseFloat(value))) {
          values.push(parseFloat(value))
        }
      })

      values.sort((a, b) => a - b)
      percentiles[col.key] = values
    })

    return percentiles
  }

  /**
   * Build table header rows
   */
  buildTableHeaders(columns) {
    // Group columns by category for header rows
    const categories = {}
    columns.forEach(col => {
      if (!categories[col.category]) {
        categories[col.category] = []
      }
      categories[col.category].push(col)
    })

    // Build category header row
    const categoryKeys = Object.keys(categories)
    let categoryRow = ''
    if (categoryKeys.length > 1) {
      categoryRow = '<tr>'
      Object.entries(categories).forEach(([category, cols]) => {
        if (category === 'Identifiers') {
          // Identifiers span 2 rows
          cols.forEach((col, idx) => {
            const colIndex = columns.indexOf(col)
            categoryRow += `<th rowspan="2" class="sortable cursor-pointer hover:bg-gray-100" onclick="window.sortTable(${colIndex})">${col.name}</th>`
          })
        } else {
          categoryRow += `<th colspan="${cols.length}" class="column-group bg-gray-50 font-bold text-gray-700">${category}</th>`
        }
      })
      categoryRow += '</tr>'
    }

    // Build column header row (non-identifier columns only)
    let columnRow = '<tr>'
    columns.forEach((col, index) => {
      if (col.category !== 'Identifiers') {
        columnRow += `<th class="sortable center cursor-pointer hover:bg-gray-100" onclick="window.sortTable(${index})">${col.name}</th>`
      }
    })
    columnRow += '</tr>'

    return categoryKeys.length > 1
      ? categoryRow + columnRow
      : `<tr>${columns.map((col, i) => `<th class="sortable cursor-pointer hover:bg-gray-100" onclick="window.sortTable(${i})">${col.name}</th>`).join('')}</tr>`
  }

  /**
   * Build a single table row
   */
  buildTableRow(example, columns) {
    const cells = columns.map(col => {
      const value = example[col.key]
      return this.buildTableCell(col.key, value, example)
    }).join('')

    return `<tr data-example-id="${example.id}">${cells}</tr>`
  }

  /**
   * Build a single table cell with appropriate formatting
   */
  buildTableCell(columnKey, value, example) {
    // Name column - link to show page
    if (columnKey === 'name') {
      return `<td class="font-medium text-blue-600">${value || '-'}</td>`
    }

    // Category column
    if (columnKey === 'category') {
      const badges = {
        'ui_pattern': '<span class="px-2 py-1 text-xs rounded bg-purple-100 text-purple-700">UI</span>',
        'backend_pattern': '<span class="px-2 py-1 text-xs rounded bg-green-100 text-green-700">Backend</span>',
        'data_pattern': '<span class="px-2 py-1 text-xs rounded bg-blue-100 text-blue-700">Data</span>',
        'deployment_pattern': '<span class="px-2 py-1 text-xs rounded bg-orange-100 text-orange-700">Deploy</span>'
      }
      return `<td class="text-center">${badges[value] || value || '-'}</td>`
    }

    // Status column
    if (columnKey === 'status') {
      const badges = {
        'new': '<span class="px-2 py-1 text-xs rounded bg-blue-100 text-blue-700">New</span>',
        'in_progress': '<span class="px-2 py-1 text-xs rounded bg-yellow-100 text-yellow-700">In Progress</span>',
        'completed': '<span class="px-2 py-1 text-xs rounded bg-green-100 text-green-700">Completed</span>',
        'archived': '<span class="px-2 py-1 text-xs rounded bg-gray-100 text-gray-700">Archived</span>'
      }
      return `<td class="text-center">${badges[value] || value || '-'}</td>`
    }

    // Numeric columns
    if (value === null || value === undefined || value === '') {
      return `<td class="number text-center text-gray-400">-</td>`
    }

    // Format numeric value
    let formatted = value
    if (typeof value === 'number') {
      formatted = value.toFixed(1)
    }

    // Percentile highlighting (top performers)
    let percentileClass = ''
    if (this.columnPercentiles && this.columnPercentiles[columnKey]) {
      const percentile = this.getPercentile(parseFloat(value), this.columnPercentiles[columnKey])
      if (percentile >= 95) {
        percentileClass = 'bg-green-100 font-bold'
      } else if (percentile >= 90) {
        percentileClass = 'bg-green-50'
      } else if (percentile >= 75) {
        percentileClass = 'bg-yellow-50'
      }
    }

    return `<td class="number text-center ${percentileClass}">${formatted}</td>`
  }

  /**
   * Render the column configuration modal
   */
  renderModal() {
    const hiddenCols = this.allColumns.filter(c => this.hiddenColumns.includes(c.key))
    const shownCols = this.allColumns.filter(c => this.shownColumns.includes(c.key) && !this.featuredColumns[c.key])
    const featuredCols = this.allColumns.filter(c => this.featuredColumns[c.key])

    this.hiddenListTarget.innerHTML = this.renderColumnList(hiddenCols, 'hidden')
    this.shownListTarget.innerHTML = this.renderColumnList(shownCols, 'shown')
    this.featuredListTarget.innerHTML = this.renderColumnList(featuredCols, 'featured')

    // Update counts
    document.getElementById('hidden-count').textContent = hiddenCols.length
    document.getElementById('shown-count').textContent = shownCols.length
    document.getElementById('featured-count').textContent = featuredCols.length
  }

  /**
   * Render a list of columns for the modal
   */
  renderColumnList(columns, state) {
    if (columns.length === 0) {
      return '<p class="text-sm text-gray-400 italic p-4">No columns</p>'
    }

    return columns.map(col => {
      let buttons = ''

      if (state === 'hidden') {
        buttons = `<span class="text-gray-400 hover:text-gray-600 cursor-pointer" data-action="click->filter#moveToShown" data-column="${col.key}">→</span>`
      } else if (state === 'shown') {
        buttons = `
          <div class="flex gap-2">
            <span class="text-gray-400 hover:text-gray-600 cursor-pointer" data-action="click->filter#moveToHidden" data-column="${col.key}" title="Hide column">←</span>
            ${col.filterable ? `<span class="text-gray-400 hover:text-blue-600 cursor-pointer" data-action="click->filter#moveToFeatured" data-column="${col.key}" title="Add filter">★</span>` : ''}
          </div>
        `
      } else {
        buttons = `<span class="text-gray-400 hover:text-red-600 cursor-pointer" data-action="click->filter#moveToShown" data-column="${col.key}" title="Remove filter">✕</span>`
      }

      return `
        <div class="flex items-center justify-between px-3 py-2 hover:bg-gray-50 rounded">
          <span class="text-sm text-gray-700">${col.name}</span>
          ${buttons}
        </div>
      `
    }).join('')
  }

  /**
   * Render the filter bar with active sliders
   */
  renderFilterBar() {
    const featuredCols = Object.keys(this.featuredColumns)

    if (featuredCols.length === 0) {
      this.filterBarTarget.classList.add('hidden')
      return
    }

    this.filterBarTarget.classList.remove('hidden')

    const html = `
      <div class="bg-gray-50 border-b border-gray-200 p-4 mb-4">
        <div class="flex justify-between items-center mb-3">
          <h3 class="text-sm font-semibold text-gray-700">
            Active Filters (${featuredCols.length})
          </h3>
          <div class="flex gap-2">
            <button data-action="click->filter#toggleFilters"
                    data-filter-target="toggleButton"
                    class="text-sm text-gray-600 hover:text-gray-800">Hide</button>
            <button data-action="click->filter#clearAllFilters"
                    class="text-sm text-blue-600 hover:text-blue-800">Clear All</button>
            <button data-action="click->filter#openModal"
                    class="text-sm text-gray-600 hover:text-gray-800">⚙️ Configure</button>
          </div>
        </div>
        <div class="space-y-3" data-filter-target="filtersContent">
          ${featuredCols.map(key => this.renderSlider(key)).join('')}
        </div>
      </div>
    `

    this.filterBarTarget.innerHTML = html
  }

  /**
   * Toggle filter bar visibility
   */
  toggleFilters() {
    const content = this.filterBarTarget.querySelector('[data-filter-target="filtersContent"]')
    const toggleButton = this.filterBarTarget.querySelector('[data-filter-target="toggleButton"]')

    if (!content || !toggleButton) return

    const isHidden = content.style.display === 'none'

    if (isHidden) {
      content.style.display = ''
      toggleButton.textContent = 'Hide'
    } else {
      content.style.display = 'none'
      toggleButton.textContent = 'Show'
    }
  }

  /**
   * Render a dual-handle slider for a column
   */
  renderSlider(columnKey) {
    const column = this.allColumns.find(c => c.key === columnKey)
    const filter = this.featuredColumns[columnKey]
    const valueRange = this.getValueRangeForPercentile(columnKey, filter.min, filter.max)

    const labelText = valueRange
      ? `${filter.min}th-${filter.max}th percentile (${valueRange})`
      : `${filter.min}th-${filter.max}th percentile`

    const mode = filter.mode || 'filter'
    const modeButtonText = mode === 'filter' ? 'Filter' : 'Elimination'
    const modeButtonClass = mode === 'filter' ? 'bg-blue-100 text-blue-700' : 'bg-red-100 text-red-700'

    return `
      <div class="slider-container">
        <div class="slider-header">
          <span class="slider-label">${column.name}</span>
          <button data-action="click->filter#toggleMode"
                  data-column="${columnKey}"
                  class="text-xs px-2 py-1 rounded ${modeButtonClass}"
                  style="font-size: 11px; margin-left: 8px;">
            ${modeButtonText}
          </button>
          <span class="slider-range" data-percentile-label="${columnKey}" style="flex: 1; text-align: center;">
            ${labelText}
          </span>
          <button data-action="click->filter#removeFilter"
                  data-column="${columnKey}"
                  class="slider-remove">✕</button>
        </div>
        <div class="dual-slider">
          <input type="range"
                 min="0" max="100"
                 value="${filter.min}"
                 data-column="${columnKey}"
                 data-handle="min"
                 data-action="input->filter#updateSlider"
                 class="slider-min">
          <input type="range"
                 min="0" max="100"
                 value="${filter.max}"
                 data-column="${columnKey}"
                 data-handle="max"
                 data-action="input->filter#updateSlider"
                 class="slider-max">
          <div class="slider-track">
            <div class="slider-range-fill"
                 data-range-fill="${columnKey}"
                 style="left: ${filter.min}%; width: ${filter.max - filter.min}%;"></div>
          </div>
        </div>
      </div>
    `
  }

  /**
   * Update slider values and reapply filters
   */
  updateSlider(event) {
    const column = event.target.dataset.column
    const handle = event.target.dataset.handle
    const value = parseInt(event.target.value)

    if (handle === 'min') {
      this.featuredColumns[column].min = value
      if (value > this.featuredColumns[column].max) {
        this.featuredColumns[column].max = value
      }
    } else {
      this.featuredColumns[column].max = value
      if (value < this.featuredColumns[column].min) {
        this.featuredColumns[column].min = value
      }
    }

    this.updatePercentileLabel(column)
    this.updateRangeFill(column)
    this.saveState()
    this.applyFilters()
  }

  /**
   * Update the percentile label with value range
   */
  updatePercentileLabel(column) {
    const label = this.filterBarTarget.querySelector(`[data-percentile-label="${column}"]`)
    if (label) {
      const filter = this.featuredColumns[column]
      const valueRange = this.getValueRangeForPercentile(column, filter.min, filter.max)

      if (valueRange) {
        label.textContent = `${filter.min}th-${filter.max}th percentile (${valueRange})`
      } else {
        label.textContent = `${filter.min}th-${filter.max}th percentile`
      }
    }
  }

  /**
   * Get value range for a percentile range
   */
  getValueRangeForPercentile(column, minPercentile, maxPercentile) {
    const columnData = this.percentileValues[column]
    if (!columnData) return null

    const minValue = this.interpolateValue(columnData, minPercentile)
    const maxValue = this.interpolateValue(columnData, maxPercentile)

    if (minValue === null || maxValue === null) return null

    return `${minValue.toFixed(1)} to ${maxValue.toFixed(1)}`
  }

  /**
   * Interpolate value at a specific percentile
   */
  interpolateValue(columnData, percentile) {
    const lowerP = Math.floor(percentile / 5) * 5
    const upperP = Math.ceil(percentile / 5) * 5

    if (lowerP === upperP) {
      return columnData[lowerP] || null
    }

    const lowerV = columnData[lowerP]
    const upperV = columnData[upperP]

    if (lowerV === undefined || upperV === undefined) return null

    const fraction = (percentile - lowerP) / (upperP - lowerP)
    return lowerV + fraction * (upperV - lowerV)
  }

  /**
   * Update the visual range fill for a slider
   */
  updateRangeFill(column) {
    const fill = this.filterBarTarget.querySelector(`[data-range-fill="${column}"]`)
    if (fill) {
      const filter = this.featuredColumns[column]
      fill.style.left = `${filter.min}%`
      fill.style.width = `${filter.max - filter.min}%`
    }
  }

  /**
   * Handle search input
   */
  handleSearch(event) {
    this.searchTerm = event.target.value.toLowerCase().trim()
    this.applyFilters()
  }

  /**
   * Apply all active filters to table rows
   *
   * Three-pass system:
   * 0. Search: Hide rows that don't match search term
   * 1. Filter mode: Hide rows that don't match
   * 2. Elimination mode: Highlight failing cells in visible rows
   */
  applyFilters() {
    const featuredCols = Object.keys(this.featuredColumns)

    // Check if we have no filters or search
    if (featuredCols.length === 0 && !this.searchTerm) {
      // Show all rows, remove all highlighting
      this.allRows.forEach(row => {
        row.style.display = ''
        row.classList.remove('eliminated-row')
        Array.from(row.cells).forEach(cell => cell.classList.remove('elimination-fail'))
      })
      this.updateResultCount(this.allRows.length)
      return
    }

    // Separate filter and elimination columns
    const filterCols = featuredCols.filter(key => {
      const mode = this.featuredColumns[key].mode || 'filter'
      return mode === 'filter'
    })
    const eliminationCols = featuredCols.filter(key => {
      const mode = this.featuredColumns[key].mode || 'filter'
      return mode === 'elimination'
    })

    // Calculate percentiles for all featured columns
    const percentiles = this.calculatePercentiles(featuredCols)

    let visibleCount = 0

    this.allRows.forEach(row => {
      // Clear previous elimination highlighting
      row.classList.remove('eliminated-row')
      Array.from(row.cells).forEach(cell => cell.classList.remove('elimination-fail'))

      // PASS 0: Check search term (if present)
      if (this.searchTerm) {
        const rowText = Array.from(row.cells).map(cell => cell.textContent.toLowerCase()).join(' ')
        if (!rowText.includes(this.searchTerm)) {
          row.style.display = 'none'
          return
        }
      }

      // FIRST PASS: Check filter-mode columns (hide if fails)
      let passesFilters = true
      for (const colKey of filterCols) {
        const filter = this.featuredColumns[colKey]
        const cellIndex = this.getColumnIndex(colKey)
        const cell = row.cells[cellIndex]
        const value = parseFloat(cell.textContent.trim())

        if (isNaN(value)) {
          passesFilters = false
          break
        }

        const percentile = this.getPercentile(value, percentiles[colKey])
        if (percentile < filter.min || percentile > filter.max) {
          passesFilters = false
          break
        }
      }

      if (!passesFilters) {
        row.style.display = 'none'
        return
      }

      // Row passes filters, so it's visible
      row.style.display = ''
      visibleCount++

      // SECOND PASS: Check elimination-mode columns (highlight if fails)
      let failedElimination = false
      for (const colKey of eliminationCols) {
        const filter = this.featuredColumns[colKey]
        const cellIndex = this.getColumnIndex(colKey)
        const cell = row.cells[cellIndex]
        const value = parseFloat(cell.textContent.trim())

        if (isNaN(value)) continue

        const percentile = this.getPercentile(value, percentiles[colKey])
        if (percentile < filter.min || percentile > filter.max) {
          failedElimination = true
          cell.classList.add('elimination-fail')
        }
      }

      if (failedElimination) {
        row.classList.add('eliminated-row')
      }
    })

    this.updateResultCount(visibleCount)
  }

  /**
   * Calculate percentiles for specified columns
   */
  calculatePercentiles(columns) {
    const percentiles = {}

    columns.forEach(colKey => {
      const values = []
      const cellIndex = this.getColumnIndex(colKey)

      this.allRows.forEach(row => {
        const cell = row.cells[cellIndex]
        const value = parseFloat(cell.textContent.trim())
        if (!isNaN(value)) {
          values.push(value)
        }
      })

      values.sort((a, b) => a - b)
      percentiles[colKey] = values
    })

    return percentiles
  }

  /**
   * Get percentile rank for a value in a sorted array
   */
  getPercentile(value, sortedValues) {
    if (sortedValues.length === 0) return 0

    let count = 0
    for (const v of sortedValues) {
      if (v <= value) count++
      else break
    }

    return Math.round((count / sortedValues.length) * 100)
  }

  /**
   * Get the index of a column in the currently visible columns
   */
  getColumnIndex(columnKey) {
    const visibleColumns = this.allColumns.filter(c =>
      this.shownColumns.includes(c.key) || this.featuredColumns[c.key]
    )

    const index = visibleColumns.findIndex(c => c.key === columnKey)
    return index >= 0 ? index : 0
  }

  /**
   * Update the result count display
   */
  updateResultCount(count) {
    if (this.hasResultCountTarget) {
      this.resultCountTarget.textContent = `Showing ${count} of ${this.allRows.length} examples`
    }
  }

  // ========== Modal Actions ==========

  openModal() {
    this.modalTarget.classList.remove('hidden')
  }

  closeModal() {
    this.modalTarget.classList.add('hidden')
  }

  moveToShown(event) {
    const column = event.currentTarget.dataset.column
    this.hiddenColumns = this.hiddenColumns.filter(c => c !== column)
    if (!this.shownColumns.includes(column)) {
      this.shownColumns.push(column)
    }
    delete this.featuredColumns[column]
    this.saveState()
    this.renderModal()
  }

  moveToFeatured(event) {
    const column = event.currentTarget.dataset.column
    this.shownColumns = this.shownColumns.filter(c => c !== column)
    this.featuredColumns[column] = { min: 0, max: 100, mode: 'filter' }
    this.saveState()
    this.renderModal()
    this.renderFilterBar()
  }

  toggleMode(event) {
    const column = event.currentTarget.dataset.column
    const currentMode = this.featuredColumns[column].mode || 'filter'
    this.featuredColumns[column].mode = currentMode === 'filter' ? 'elimination' : 'filter'
    this.saveState()
    this.renderFilterBar()
    this.applyFilters()
  }

  moveToHidden(event) {
    const column = event.currentTarget.dataset.column
    this.shownColumns = this.shownColumns.filter(c => c !== column)
    delete this.featuredColumns[column]
    if (!this.hiddenColumns.includes(column)) {
      this.hiddenColumns.push(column)
    }
    this.saveState()
    this.renderModal()
  }

  removeFilter(event) {
    const column = event.currentTarget.dataset.column
    delete this.featuredColumns[column]
    if (!this.shownColumns.includes(column)) {
      this.shownColumns.push(column)
    }
    this.saveState()
    this.renderModal()
    this.renderFilterBar()
    this.applyFilters()
  }

  clearAllFilters() {
    Object.keys(this.featuredColumns).forEach(key => {
      if (!this.shownColumns.includes(key)) {
        this.shownColumns.push(key)
      }
    })
    this.featuredColumns = {}
    this.saveState()
    this.renderModal()
    this.renderFilterBar()
    this.applyFilters()
  }

  saveConfiguration() {
    this.saveState()
    this.buildTable()
    this.renderFilterBar()
    this.applyFilters()
    this.closeModal()
  }

  resetConfiguration() {
    if (confirm('Reset all column and filter settings to defaults?')) {
      localStorage.removeItem('exampleFilterState')
      location.reload()
    }
  }
}

/**
 * Global sortTable function for table header clicks
 * Sorts visible rows by column index
 */
window.sortTable = function(columnIndex) {
  const table = document.querySelector('[data-filter-target="table"]')
  const tbody = table.querySelector('tbody')
  const rows = Array.from(tbody.querySelectorAll('tr[style=""]'))  // Only visible rows

  // Get current sort direction from header
  const headers = table.querySelectorAll('th')
  const header = headers[columnIndex]
  const currentSort = header.dataset.sort || ''
  const newSort = currentSort === 'asc' ? 'desc' : 'asc'

  // Clear all header sorts and indicators
  headers.forEach(th => {
    th.dataset.sort = ''
    // Remove any existing sort indicators
    const text = th.textContent.replace(/ [▲▼]$/, '')
    th.textContent = text
  })

  // Set new sort and add indicator
  header.dataset.sort = newSort
  const headerText = header.textContent.replace(/ [▲▼]$/, '')
  header.textContent = headerText + (newSort === 'asc' ? ' ▲' : ' ▼')

  // Sort rows
  rows.sort((a, b) => {
    let aVal = a.cells[columnIndex].textContent.trim()
    let bVal = b.cells[columnIndex].textContent.trim()

    // Try numeric sort first
    const aNum = parseFloat(aVal)
    const bNum = parseFloat(bVal)

    if (!isNaN(aNum) && !isNaN(bNum)) {
      return newSort === 'asc' ? aNum - bNum : bNum - aNum
    }

    // Fall back to text sort
    return newSort === 'asc'
      ? aVal.localeCompare(bVal)
      : bVal.localeCompare(aVal)
  })

  // Reattach sorted rows
  rows.forEach(row => tbody.appendChild(row))
}
