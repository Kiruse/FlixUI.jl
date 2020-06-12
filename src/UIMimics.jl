######################################################################
# Generic methods for mimics.
# Mimics mimic another UIElement with some altered behavior. Generic
# methods include those required by FlixGL to properly render the mimic.

FlixGL.wantsrender(mimic::AbstractUIMimic) = FlixGL.wantsrender(mimicked(mimic))
FlixGL.vertsof(    mimic::AbstractUIMimic) = FlixGL.vertsof(    mimicked(mimic))
FlixGL.countverts( mimic::AbstractUIMimic) = FlixGL.countverts( mimicked(mimic))
FlixGL.vaoof(      mimic::AbstractUIMimic) = FlixGL.vaoof(      mimicked(mimic))
FlixGL.materialof( mimic::AbstractUIMimic) = FlixGL.materialof( mimicked(mimic))
FlixGL.drawmodeof( mimic::AbstractUIMimic) = FlixGL.drawmodeof( mimicked(mimic))

FlixGL.isvisible(mimic::AbstractUIMimic)      = FlixGL.isvisible(mimicked(mimic))
FlixGL.setvisibility!(mimic::AbstractUIMimic) = FlixGL.setvisibility(mimicked(mimic))

VPECore.bounds(mimic::AbstractUIMimic) = VPECore.bounds(mimicked(mimic))
VPECore.transformof(mimic::AbstractUIMimic) = VPECore.transformof(mimicked(mimic))

Base.size(mimic::AbstractUIMimic) = size(mimicked(mimic))
