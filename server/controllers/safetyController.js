const { getSupabaseClient } = require('../config/supabase');

// @desc    Get checklist for sale
// @route   GET /api/safety/checklists/sale/:saleId
// @access  Private
const getChecklistForSale = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: checklist, error } = await supabase
      .from('safety_checklists')
      .select('*')
      .eq('sale_id', req.params.saleId)
      .single();

    if (error && error.code !== 'PGRST116') throw error;

    res.json({
      success: true,
      data: checklist || null
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create safety checklist
// @route   POST /api/safety/checklists
// @access  Private
const createChecklist = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const checklistData = {
      sale_id: req.body.sale_id,
      cylinder_id: req.body.cylinder_id || null,
      checked_by: req.user.id,
      check_date: new Date().toISOString(),
      items: req.body.items || [],
      passed: req.body.passed || false,
      notes: req.body.notes || null
    };

    const { data: checklist, error } = await supabase
      .from('safety_checklists')
      .insert([checklistData])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Safety checklist created successfully',
      data: checklist
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Check item in checklist
// @route   PUT /api/safety/checklists/:id/items/:itemId
// @access  Private
const checkItem = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    // Get current checklist
    const { data: checklist, error: fetchError } = await supabase
      .from('safety_checklists')
      .select('items')
      .eq('id', req.params.id)
      .single();

    if (fetchError || !checklist) {
      return res.status(404).json({
        success: false,
        message: 'Checklist not found'
      });
    }

    // Update the specific item
    const items = checklist.items || [];
    const itemIndex = items.findIndex(item => item.id === req.params.itemId);
    
    if (itemIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Item not found in checklist'
      });
    }

    items[itemIndex] = {
      ...items[itemIndex],
      checked: req.body.checked,
      checked_by: req.user.id,
      checked_at: new Date().toISOString(),
      notes: req.body.notes || items[itemIndex].notes
    };

    const { data: updated, error } = await supabase
      .from('safety_checklists')
      .update({ items })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: 'Checklist item updated successfully',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add acknowledgment to checklist
// @route   POST /api/safety/checklists/:id/acknowledge
// @access  Private
const addAcknowledgment = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: checklist, error } = await supabase
      .from('safety_checklists')
      .update({
        passed: req.body.passed,
        notes: req.body.notes || null
      })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!checklist) {
      return res.status(404).json({
        success: false,
        message: 'Checklist not found'
      });
    }

    res.json({
      success: true,
      message: 'Acknowledgment added successfully',
      data: checklist
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Report safety incident
// @route   POST /api/safety/incidents
// @access  Private
const reportIncident = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const incidentData = {
      incident_date: req.body.incident_date || new Date().toISOString(),
      location: req.body.location,
      description: req.body.description,
      severity: req.body.severity || 'medium',
      reported_by: req.user.id,
      status: 'reported'
    };

    const { data: incident, error } = await supabase
      .from('safety_incidents')
      .insert([incidentData])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Safety incident reported successfully',
      data: incident
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get safety incidents
// @route   GET /api/safety/incidents
// @access  Private
const getIncidents = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    let query = supabase
      .from('safety_incidents')
      .select('*, users(name)')
      .order('incident_date', { ascending: false });

    if (req.query.status) {
      query = query.eq('status', req.query.status);
    }

    if (req.query.severity) {
      query = query.eq('severity', req.query.severity);
    }

    const { data: incidents, error } = await query;

    if (error) throw error;

    res.json({
      success: true,
      count: incidents?.length || 0,
      data: incidents || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update incident status
// @route   PUT /api/safety/incidents/:id/status
// @access  Private
const updateIncidentStatus = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const updateData = {
      status: req.body.status
    };

    if (req.body.resolution) {
      updateData.resolution = req.body.resolution;
    }

    if (req.body.status === 'resolved') {
      updateData.resolved_at = new Date().toISOString();
    }

    const { data: incident, error } = await supabase
      .from('safety_incidents')
      .update(updateData)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!incident) {
      return res.status(404).json({
        success: false,
        message: 'Incident not found'
      });
    }

    res.json({
      success: true,
      message: 'Incident status updated successfully',
      data: incident
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get compliance report
// @route   GET /api/safety/compliance-report
// @access  Private
const getComplianceReport = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    // Get checklists summary
    const { data: checklists, error: checklistError } = await supabase
      .from('safety_checklists')
      .select('passed');

    if (checklistError) throw checklistError;

    // Get incidents summary
    const { data: incidents, error: incidentError } = await supabase
      .from('safety_incidents')
      .select('severity, status');

    if (incidentError) throw incidentError;

    const report = {
      checklists: {
        total: checklists?.length || 0,
        passed: checklists?.filter(c => c.passed).length || 0,
        failed: checklists?.filter(c => !c.passed).length || 0
      },
      incidents: {
        total: incidents?.length || 0,
        open: incidents?.filter(i => i.status !== 'resolved').length || 0,
        resolved: incidents?.filter(i => i.status === 'resolved').length || 0,
        bySeverity: {
          low: incidents?.filter(i => i.severity === 'low').length || 0,
          medium: incidents?.filter(i => i.severity === 'medium').length || 0,
          high: incidents?.filter(i => i.severity === 'high').length || 0,
          critical: incidents?.filter(i => i.severity === 'critical').length || 0
        }
      }
    };

    res.json({
      success: true,
      data: report
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getChecklistForSale,
  createChecklist,
  checkItem,
  addAcknowledgment,
  reportIncident,
  getIncidents,
  updateIncidentStatus,
  getComplianceReport
};
