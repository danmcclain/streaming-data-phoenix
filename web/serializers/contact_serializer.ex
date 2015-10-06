defmodule StreamingData.ContactSerializer do
  use JaSerializer

  attributes [:first_name, :last_name, :title]
end
