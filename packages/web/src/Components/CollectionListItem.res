@react.component
let make = (
  ~imageUrl,
  ~primary,
  ~secondary,
  ~bare=false,
  ~disableGutters=false,
  ~listItemClasses=?,
) => {
  let contents =
    <>
      <MaterialUi.Avatar>
        {imageUrl
        ->Belt.Option.map(imageUrl => <img src=imageUrl />)
        ->Belt.Option.getWithDefault(React.null)}
      </MaterialUi.Avatar>
      <MaterialUi.ListItemText
        classes={MaterialUi.ListItemText.Classes.make(~root=Cn.make(["ml-4"]), ())}
        primary={primary->React.string}
        secondary={secondary->React.string}
      />
    </>

  bare
    ? contents
    : <MaterialUi.ListItem disableGutters classes=?{listItemClasses}>
        {contents}
      </MaterialUi.ListItem>
}