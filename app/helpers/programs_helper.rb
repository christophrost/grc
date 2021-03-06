module ProgramsHelper
  # Set up a program and relevant stats for display
  def program_stats(program)
    stats = {}
    stats[:sections_count] = Section.where(:program_id => program.id).count()
    stats[:sections_done_count] = Section.joins(:controls).where(:program_id => program.id).count(:distinct => true)
    stats[:sections_na_count] = Section.where(:program_id => program.id, :na => true).count()
    stats[:sections_undone_count] = Section.where(:program_id => program.id).count() - stats[:sections_done_count] - stats[:sections_na_count]

    if stats[:sections_count] > 0
      stats[:sections_done_percentage] = 100.0 * stats[:sections_done_count] / stats[:sections_count]
      stats[:sections_na_percentage] = 100.0 * stats[:sections_na_count] / stats[:sections_count]
      stats[:sections_undone_percentage] = 100.0 * stats[:sections_undone_count] / stats[:sections_count]
    end

    controls = Control.joins(:sections).where(Section.arel_table[:program_id].eq(program.id))
    stats[:controls_count] = controls.count(:distinct => true)
    stats[:controls_parented_count] = controls.where(Control.arel_table[:parent_id].not_eq(nil)).count(:distinct => true)

    stats[:controls_complying_count] = stats[:controls_count] / 3
    stats[:controls_approved_count] = stats[:controls_count] / 2 - stats[:controls_complying_count]
    stats[:controls_pending_count] = stats[:controls_count] - stats[:controls_approved_count] - stats[:controls_complying_count]

    if stats[:controls_count] > 0
      stats[:controls_approved_percentage] = 100.0 * stats[:controls_approved_count] / stats[:controls_count]
      stats[:controls_complying_percentage] = 100.0 * stats[:controls_complying_count] / stats[:controls_count]
      stats[:controls_pending_percentage] = 100.0 * stats[:controls_pending_count] / stats[:controls_count]
    end

    stats
  end
end
