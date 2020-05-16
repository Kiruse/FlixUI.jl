export UIInputConfig, WantsNoInput, WantsMouseInput, WantsKeyboardInput, WantsTextInput, WantsScrollInput

@bitflag UIInputConfig begin
    WantsNoInput = 0
    WantsMouseInput
    WantsKeyboardInput
    WantsTextInput
    WantsScrollInput
end
Base.:∈(val::UIInputConfig, conf::UIInputConfig) = (val & conf) != WantsNoInput
Base.:+(val::UIInputConfig, conf::UIInputConfig) = val | conf
