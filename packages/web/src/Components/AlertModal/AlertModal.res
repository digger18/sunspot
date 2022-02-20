let styles = %raw("require('./AlertModal.module.css')")

module Value = AlertModal_DialogContent.Value
module CollectionOption = AlertModal_Types.CollectionOption
module Utils = AlertModal_Utils

let validate = value => {
  let collectionValidation = switch value->Value.collection {
  | None => Some("collection is required")
  | Some(_) => None
  }
  let priceRuleValidation = switch value->Value.priceRule {
  | Some({modifier}) if Js.String2.length(modifier) == 0 => Some("price rule modifier is required.")
  | Some({value: None}) => Some("price rule value is required.")
  | Some({value: Some(value)}) =>
    switch Belt.Float.fromString(value) {
    | Some(value) if value <= 0.00 => Some("price rule value must be a positive number.")
    | None => Some("price rule value must be a positive number.")
    | _ => None
    }
  | None => None
  }
  let propertiesRuleValidation = switch value->Value.propertiesRule {
  | Some(value) if Belt.Array.length(value) == 0 =>
    Some("properties rule value must include properties")
  | _ => None
  }
  let destinationValidation = switch value->Value.destination {
  | None => Some("destination is required.")
  | Some(DiscordAlertDestination({template: Some({fields: Some(fields)})})) =>
    if (
      Belt.Array.some(fields, field =>
        field->AlertRule_Destination_Types.DiscordTemplate.name->Js.String2.length == 0 ||
          field->AlertRule_Destination_Types.DiscordTemplate.value->Js.String2.length == 0
      )
    ) {
      Some("discord template fields must not contain empty name or value.")
    } else {
      None
    }
  | Some(_) => None
  }

  let quantityRuleValidation = switch value->Value.quantityRule {
  | Some({modifier}) if Js.String2.length(modifier) == 0 =>
    Some("quantity rule modifier is required.")
  | Some({value: None}) => Some("quantity rule value is required.")
  | Some({value: Some(value)}) =>
    switch value->Belt.Int.fromString {
    | Some(value) if value <= 0 => Some("quantity rule value must be a positive whole number.")
    | Some(parsedValue)
      if parsedValue->Belt.Float.fromInt !==
        value->Belt.Float.fromString->Belt.Option.getWithDefault(-1.) =>
      Some("quantity rule value must be a positive whole number.")
    | None => Some("quantity rule value must be a positive number.")
    | _ => None
    }
  | None => None
  }

  [
    collectionValidation,
    priceRuleValidation,
    propertiesRuleValidation,
    quantityRuleValidation,
    destinationValidation,
  ]
  ->Belt.Array.keepMap(i => i)
  ->Belt.Array.get(0)
}

@react.component
let make = (
  ~isOpen,
  ~onClose,
  ~onExited=?,
  ~value,
  ~destinationOptions,
  ~onChange,
  ~onAction,
  ~actionLabel,
  ~title,
  ~renderOverflowActionMenuItems=?,
) => {
  let (isExited, setIsExited) = React.useState(_ => isOpen)
  let (validationError, setValidationError) = React.useState(_ => None)
  let (isActioning, setIsActioning) = React.useState(_ => false)

  let _ = React.useEffect1(() => {
    if isOpen {
      setIsExited(_ => false)
    }
    None
  }, [isOpen])

  let handleExited = () => {
    setIsExited(_ => true)
    setValidationError(_ => None)
    onExited->Belt.Option.forEach(fn => fn())
  }

  let handleAction = () => {
    let validationResult = validate(value)
    setValidationError(_ => validationResult)
    switch validationResult {
    | None =>
      setIsActioning(_ => true)
      let _ =
        onAction()
        |> Js.Promise.then_(_ => {
          setIsActioning(_ => false)
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(_ => {
          setIsActioning(_ => false)
          Js.Promise.resolve()
        })
    | Some(_) => ()
    }
  }

  <MaterialUi.Dialog
    _open={isOpen}
    onClose={(_, _) => onClose()}
    onExited={_ => handleExited()}
    classes={MaterialUi.Dialog.Classes.make(~paper=styles["dialogPaper"], ())}>
    <MaterialUi.DialogTitle
      disableTypography=true
      classes={MaterialUi.DialogTitle.Classes.make(
        ~root=Cn.make(["flex", "justify-between", "items-center"]),
        (),
      )}>
      <MaterialUi.Typography
        color=#Primary
        variant=#H6
        classes={MaterialUi.Typography.Classes.make(~root=Cn.make(["leading-none"]), ())}>
        {React.string(title)}
      </MaterialUi.Typography>
      <div className={Cn.make(["flex", "flex-row", "items-center"])}>
        {value
        ->Value.disabled
        ->Belt.Option.map(disabled => {
          let title = switch disabled {
          | Snoozed => "alert has been disabled."
          | DestinationMissingAccess => "unable to connect to the destination. try reconnecting or adjusting permissions and re-enable."
          | DestinationRateLimitExceeded(
              _,
            ) => "alert has been ratelimited and will automatically re-enable after a period of time."
          }

          <MaterialUi.Tooltip title={React.string(title)}>
            <Externals.MaterialUi_Icons.Error
              className={Cn.make(["w-6", "h-6", "mr-2", "text-red-400"])}
            />
          </MaterialUi.Tooltip>
        })
        ->Belt.Option.getWithDefault(React.null)}
        {renderOverflowActionMenuItems
        ->Belt.Option.map(renderOverflowActionMenuItems =>
          <IconMenu
            icon={<Externals.MaterialUi_Icons.MoreVert />}
            renderItems={renderOverflowActionMenuItems}
            anchorOrigin={
              open MaterialUi.Menu
              AnchorOrigin.make(
                ~horizontal=Horizontal.enum(Horizontal_enum.left),
                ~vertical=Vertical.enum(Vertical_enum.bottom),
                (),
              )
            }
            menuClasses={MaterialUi.Menu.Classes.make(~paper=Cn.make(["bg-gray-100"]), ())}
          />
        )
        ->Belt.Option.getWithDefault(React.null)}
      </div>
    </MaterialUi.DialogTitle>
    <MaterialUi.DialogContent
      classes={MaterialUi.DialogContent.Classes.make(~root=Cn.make(["flex", "flex-col"]), ())}>
      <AlertModal_DialogContent
        value={value}
        isExited={isExited}
        onChange={onChange}
        validationError={validationError}
        destinationOptions={destinationOptions}
      />
    </MaterialUi.DialogContent>
    <MaterialUi.DialogActions
      classes={MaterialUi.DialogActions.Classes.make(~root=Cn.make(["mt-8"]), ())}>
      <MaterialUi.Button
        variant=#Text
        color=#Primary
        disabled={isActioning}
        onClick={_ => onClose()}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["mr-2"]),
          ~label=Cn.make(["normal-case", "leading-none", "py-1"]),
          (),
        )}>
        {React.string("cancel")}
      </MaterialUi.Button>
      <MaterialUi.Button
        variant=#Contained
        color=#Primary
        disabled={isActioning}
        onClick={_ => handleAction()}
        classes={MaterialUi.Button.Classes.make(
          ~label=Cn.make(["normal-case", "leading-none", "py-1", "w-16"]),
          (),
        )}>
        {isActioning
          ? <MaterialUi.CircularProgress size={MaterialUi.CircularProgress.Size.int(18)} />
          : React.string(actionLabel)}
      </MaterialUi.Button>
    </MaterialUi.DialogActions>
  </MaterialUi.Dialog>
}
